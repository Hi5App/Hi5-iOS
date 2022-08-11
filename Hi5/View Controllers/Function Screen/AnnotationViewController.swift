//
//  AnnotationViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/29.
//

import UIKit
import UniformTypeIdentifiers
import simd
import Foundation

enum spacePointsStatus{
    case ALIVE
    case FAR
    case TRIAL
}

struct heapElement:Equatable{
    var index:Int
//    var parentIndex:Int
    var distance:Float
}

struct userLines{
    var lines:[[simd_float3]]
    var lineColor:UIColor
}

struct intersectionSpace{
    var x0:Float
    var x1:Float
    var y0:Float
    var y1:Float
    var z0:Float
    var z1:Float
    
    var minPoint:(Float,Float,Float) = (0,0,0)
    var maxPoint:(Float,Float,Float) = (0,0,0)
    
    init(twoPoints:[simd_float4]){
        x0 = Float(twoPoints[0].x)
        x1 = Float(twoPoints[1].x)
        y0 = Float(twoPoints[0].y)
        y1 = Float(twoPoints[1].y)
        z0 = Float(twoPoints[0].z)
        z1 = Float(twoPoints[1].z)
    }
    
    mutating func update(twoPoints:[simd_float4]){
        x1 = max(x1, Float(max(twoPoints[0].x, twoPoints[1].x)))
        x0 = min(x0, Float(min(twoPoints[0].x, twoPoints[1].x)))
        y1 = max(y1, Float(max(twoPoints[0].y, twoPoints[1].y)))
        y0 = min(y0, Float(min(twoPoints[0].y, twoPoints[1].y)))
        z1 = max(z1, Float(max(twoPoints[0].z, twoPoints[1].z)))
        z0 = min(z0, Float(min(twoPoints[0].z, twoPoints[1].z)))
    }
    
    mutating func extendArea(extent:Float){
        x0 = max(x0-extent,-1)
        x1 = min(x1+extent,1)
        y0 = max(y0-extent,-1)
        y1 = min(y1+extent,1)
        z0 = max(z0-extent,-1)
        z1 = min(z1+extent,1)
    }
    
    mutating func setEdge(point1:(Float,Float,Float),point2:(Float,Float,Float)){
        minPoint = point1
        maxPoint = point2
    }
    
    func isInSpace(point:(Int,Int,Int))->Bool{
        return Float(point.0) >= minPoint.0 &&
        Float(point.0) <= maxPoint.0 &&
        Float(point.1) >= minPoint.1 &&
        Float(point.1) <= maxPoint.1 &&
        Float(point.2) >= minPoint.2 &&
        Float(point.2) <= maxPoint.2
    }
}

class AnnotationViewController:Image3dViewController,UIDocumentPickerDelegate,UIColorPickerViewControllerDelegate{
    
    //Controls
    @IBOutlet var modeSwitcher: UISegmentedControl!
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch modeSwitcher.selectedSegmentIndex{
        case 0:
            editStatus = .View
        case 1:
            editStatus = .Mark
        case 2:
            editStatus = .Delete
        default:
            print("unrecognized index")
        }
    }
    
    
    @IBOutlet var colorPickerItem: UIBarButtonItem!
    @IBAction func colorPicker(_ sender: Any) {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        present(colorPickerVC, animated: true)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        colorPickerItem.tintColor = color
        currentMarkerColor = color
        mapToMarkerArray()
    }
    
    var lineMarkMode:Bool = false
    @IBOutlet var lineMarkSwitch: UIBarButtonItem!
    var touchPoints:[simd_float4] = []
    @IBAction func lineMarkMode(_ sender: Any) {
        if lineMarkMode{
            lineMarkMode = false
            lineMarkSwitch.tintColor = UIColor.systemOrange
            lineMarkSwitch.image = UIImage(systemName: "scribble")
        }else{
            lineMarkMode = true
            lineMarkSwitch.tintColor = UIColor.systemBlue
            lineMarkSwitch.image = UIImage(systemName: "scribble.variable")
        }
    }
    
    
    let tracingFunctions = neuronTracing()
    @IBAction func Tracing(_ sender: Any) {
//        if self.markerArray.count == 1{
//            tracingFunctions.app2(seed: markerArray[0].displayPosition, image: self.imageToDisplay)
//        }
    }
    
    @IBAction func moreOptions(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
//        test()
        // init
        
    }
    
    var userPref:UserPreferences!
    var space:intersectionSpace!
    var globalIDCounter:Int = 0
    var drawingLines:userLines?
    
    override func renderObjects(drawable: CAMetalDrawable) {
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil, markerArray: markerArray, Tree: Tree,userLines: drawingLines)
    }
    
    // MARK: - Congfigue UI
    override func configureNavBar(){
        super.configureNavBar()
        // buttons
//        let readLocalFile = UIAction(title:"Local Image",image: UIImage(systemName: "folder.fill")){ (action) in
//            self.readLocalImage()
//        }
//        let menu = UIMenu(title: "", options: .displayInline, children: [readLocalFile])
        let openImageButton = UIBarButtonItem(systemItem: .add)
        openImageButton.target = self
        openImageButton.action = #selector(readLocalImage)
//        openImageButton.menu = menu
        let UndoButton = UIBarButtonItem()
        UndoButton.image = UIImage(systemName: "arrow.counterclockwise")
        UndoButton.target = self
        UndoButton.action = #selector(undoAMarker)
        navigationItem.rightBarButtonItems = [openImageButton,UndoButton]
    }
    
    @objc func undoAMarker(){
        if !userArray.isEmpty{
            userArray.remove(at: userArray.count-1)
            somaArray = originalSomaArray + userArray
            mapToMarkerArray()
        }else if let userLines = drawingLines,userLines.lines.count != 0{
            drawingLines?.lines.remove(at: userLines.lines.count-1)
        }
    }
    
   // MARK: - Image Reader
    @objc func readLocalImage(){
        let v3drawUTType = UTType("com.penglab.Hi5-imageType.v3draw.v3draw")!
        let swcUTType = UTType("com.penglab.Hi5-annotationType.swc")!
        let pbdUTType = UTType("com.penglab.Hi5-imageType.pbd")!
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [v3drawUTType,swcUTType,pbdUTType])
//        let documentPicker = UIDocumentPickerViewController()
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func readImageFromDocumentsFolder(filename:String){
        self.userArray.removeAll()
        self.somaArray = self.userArray + self.originalSomaArray
        mapToMarkerArray()
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        print(URL(string: filename)!.pathExtension)
        switch URL(string: filename)?.pathExtension {
        case "v3draw":
            let reader = v3drawReader()
            
            imageToDisplay = reader.read(from: fileURL)
            localImageURL = fileURL
            self.title = imageToDisplay.name
            // display image
            if let image = imageToDisplay{
                drawWithImage(image: image)
                hideMessageLabel()
            }else{
                print("No 4d image")
            }
        case "v3dpbd":
            var pbdimage = PBDImage(imageLocation: fileURL)
            imageToDisplay = pbdimage.decompressToV3draw()
            imageToDisplay.make3DArrayFrom1DArray()
            if let image = imageToDisplay{
                drawWithImage(image: image)
                hideMessageLabel()
            }else{
                print("No 4d image")
            }
        case "swc":
            Tree = neuronTree(from: fileURL)
            if let branches = Tree?.organizeBranch(){
                Tree?.branchIndexes = branches
            }
            // display image
            if let image = imageToDisplay{
                drawWithImage(image: image)
                hideMessageLabel()
            }else{
                print("No 4d image")
            }
        default:
            fatalError("Unknown File Type")
        }
        drawingLines = nil
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // Start accessing a security-scoped resource.
        Swift.debugPrint("url is \(url.path)\n")
        guard url.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return
        }

        // Make sure you release the security-scoped resource when you finish.
        defer { url.stopAccessingSecurityScopedResource() }

        // Use file coordination for reading and writing any of the URL’s content.
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { (url) in
            
            let fileManager = FileManager.default
            
            // copy item to document directory
            let appFolderDocumentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(url.lastPathComponent)")
            do{
                if !fileManager.fileExists(atPath: appFolderDocumentURL.path){
                    try fileManager.copyItem(at: url, to: appFolderDocumentURL) // copy image if it doesn't exist
                }
            }catch{
                print(error)
            }
            
            // read the selected image from document folder
            readImageFromDocumentsFolder(filename: url.lastPathComponent)
            
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    //MARK: - setup interaction with images
    override func respondEditStatusChange(){
        if editStatus == .View{
            modeSwitcher.selectedSegmentIndex = 0
            modeSwitcher.sendActions(for: UIControl.Event.valueChanged)
        }else if editStatus == .Mark{
            modeSwitcher.selectedSegmentIndex = 1
            modeSwitcher.sendActions(for: UIControl.Event.valueChanged)
        }else{
            modeSwitcher.selectedSegmentIndex = 2
            modeSwitcher.sendActions(for: UIControl.Event.valueChanged)
        }
    }
    
    //MARK: - override pan interaction
    override func pan(panGesture: UIPanGestureRecognizer) {
        if lineMarkMode{
            if panGesture.state == UIGestureRecognizer.State.changed{
                let PanLocation = panGesture.location(in: self.view)
                guard let coord = findIntersectionEnd(PanLocation) else {return}
                touchPoints.append(contentsOf: coord)
                if space == nil{
                    space = intersectionSpace(twoPoints: coord)
                }else{
                    space.update(twoPoints: coord)
                }
            }else if panGesture.state == UIGestureRecognizer.State.ended{
                // calculate curve
                guard space != nil else {return}
                let timer1 = Date()
                space.extendArea(extent: 0.1) //extend space for correcting error
                space.setEdge(point1: (imageToDisplay.access3DfromCenter(x: space.x0, y: space.y0, z: space.z0)), point2: (imageToDisplay.access3DfromCenter(x: space.x1, y: space.y1, z: space.z1)))
//                print(space)
                // data type transform: simd_float4 -> [simd_float4] -> 3d array coord float -> 3d array coord int -> spacePoints struct
                let startEnds = Array(touchPoints.prefix(2))
                print(startEnds)
                // check for bound
                let startRay = interpolateVector(points: startEnds, numberOfPoints: 40)
                let IntStartRay = startRay.map({imageToDisplay.access3DfromCenter(x: $0.x, y: $0.y, z: $0.z)}).map { point in
                    (Int(point.0),Int(point.1),Int(point.2))
                }
                
                let endEnds = Array(touchPoints.suffix(2))
                let endRay = interpolateVector(points: endEnds, numberOfPoints: 40)
                let IntEndRay = endRay.map({imageToDisplay.access3DfromCenter(x: $0.x, y: $0.y, z: $0.z)}).map { point in
                    (Int(point.0),Int(point.1),Int(point.2))
                }
                
                let arraysize = imageToDisplay.sizeX*imageToDisplay.sizeY*imageToDisplay.sizeZ
                let imageSize = (imageToDisplay.sizeX,imageToDisplay.sizeY,imageToDisplay.sizeZ)
                
                // array stores distance parent status
                var distance = Array(repeating: Float.greatestFiniteMagnitude, count: arraysize)
                var parent = Array(repeating: -1, count: arraysize)
                var status = Array(repeating: spacePointsStatus.FAR, count: arraysize)
                
                // dictionary stores start points and end points
                let startIndex = Set<Int>(IntStartRay.map({ point in
                    return CoordHelper.coord2Index(coord: point, size: imageSize)
                }))
                let endIndex = Set<Int>(IntEndRay.map({ point in
                    return CoordHelper.coord2Index(coord: point, size: imageSize)
                }))
                
                // initialize for start point
                for point in IntStartRay{
                    let index = CoordHelper.coord2Index(coord: point, size: imageSize)
                    status[index] = .ALIVE
                    parent[index] = index
                    distance[index] = 0
                }
                
                // fast marching search
                var pathEndIndex = -1
                var path = Array<Int>()
                var minHeap = heap(sort: compareHeapElement)
                for point in IntStartRay{
                    let index = CoordHelper.coord2Index(coord: point, size: imageSize)
                    let element = heapElement(index: index, distance: 0)
                    minHeap.insert(element)
                }
                while(!minHeap.isEmpty){
                    let minElement = minHeap.remove()! // take out min value of heap
                    // see if it's in end array
                    if endIndex.contains(minElement.index){
                        pathEndIndex = minElement.index
                        break
                    }
                    for point in nearPoints(around: CoordHelper.index2Coord(index: minElement.index, size: imageSize)){
                        let nearIndex = CoordHelper.coord2Index(coord: point, size: imageSize)
                        if status[nearIndex] != .ALIVE{
                            let startPosition:(Int,Int,Int) = CoordHelper.index2Coord(index: minElement.index, size: imageSize)
                            let newDistance = minElement.distance + tracingFunctions.graphDistance(from: startPosition, to: point, image: self.imageToDisplay)
                            let newElement = heapElement(index: nearIndex, distance: newDistance)
                            if status[nearIndex] == .FAR{
                                //update info
                                parent[nearIndex] = minElement.index
                                distance[nearIndex] = newDistance
                                status[nearIndex] = .TRIAL
                                // insert to heap
                                minHeap.insert(newElement)
                            }else if status[nearIndex] == .TRIAL{
                               // update info when newDistance is shorter
                                if newDistance < distance[nearIndex]{
                                    // update info
                                    distance[nearIndex] = newDistance
                                    parent[nearIndex] = minElement.index
                                    // update element in heap (remove and reinsert)
                                    guard let index = minHeap.nodes.firstIndex(where: {$0.index == nearIndex}) else {
                                        print("TRIAL objects can't be found in heap")
                                        break
                                    }
                                    minHeap.remove(at: index)
                                    minHeap.insert(newElement)
                                }
                            }
                        }
                    }
                }
                // collect path
                while(!startIndex.contains(pathEndIndex)){
                    path.append(pathEndIndex)
                    pathEndIndex = parent[pathEndIndex]
                }
                path.append(pathEndIndex)
                let timer2 = Date()
                print("Curve calculation used \(timer2.timeIntervalSince(timer1)) seconds")
                
                var positions = path.map({CoordHelper.index2Coord(index: $0, size: imageSize)})
                    .map({imageToDisplay.from3DToDisplay(position: $0)})
                    .map({simd_float3($0.0,$0.1,$0.2)})
//                print(positions)
                positions = smoothLine(line: positions,windowSize: 4)
//                print(positions)
                if drawingLines == nil{ // first line
                    let a2 = [positions]
                    drawingLines = userLines(lines:a2, lineColor: .systemRed)
                }else{ // later line
                    drawingLines?.lines.append(positions)
                }
                // reset space
                space = nil
                touchPoints = []
                minHeap.nodes.removeAll()
            }
            
        }else{
            if panGesture.state == UIGestureRecognizer.State.changed{
                let pointInView = panGesture.location(in: self.view)
                
                let xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
                let yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
                objectToDraw.rotationY -= xDelta
                objectToDraw.rotationX -= yDelta
                lastPanLocation = pointInView
            }else if panGesture.state == UIGestureRecognizer.State.began{
                if editStatus == .Mark{
                    editStatus = .View
                    respondEditStatusChange()
                }
                lastPanLocation = panGesture.location(in: self.view)
            }
        }
    }
    
    func compareHeapElement(_ point1:heapElement,_ point2:heapElement)->Bool{
        return point1.distance < point2.distance
    }
    
    func interpolateVector(points:[simd_float4],numberOfPoints:Int)->[simd_float4]{
        var start = points[0]
        let end = points[1]
        let step = (end - start)/Float(numberOfPoints)
        var steps = [simd_float4]()
        for _ in 1...numberOfPoints{
            steps.append(start)
            start += step
        }
        return steps
    }
    
    func findIntersectionEnd(_ tapPosition:CGPoint)->[simd_float4]?{ //find a start and end point for a given point
        // calculate coordinate in NDC
        let viewWidth = self.view.bounds.width
        let viewHeight = self.view.bounds.height
        let centerX = viewWidth/2
        let centerY = viewHeight/2
        let clipX = Float((tapPosition.x-centerX)/centerX)
        let clipY = Float((-tapPosition.y+centerY)/centerY)
        let clipZstart = Float(0)
        let clipZend = Float(1)
        let clipW = Float(1)
        let tapCastStart = simd_float4(clipX, clipY, clipZstart, clipW)
        let tapCastEnd = simd_float4(clipX, clipY, clipZend, clipW)
        // calculate inverse of finalMatrix
        var finalMatrix = objectToDraw.modelMatrix()
        finalMatrix.multiplyLeft(worldModelMatrix)
        finalMatrix.multiplyLeft(projectionMatrix)
        let inverseFinalMatrix = finalMatrix.inverse
        // calculate tapCast in model space, ms stands for model space
        var msTapCastStart = matrix_multiply(inverseFinalMatrix, tapCastStart)
        var msTapCastEnd = matrix_multiply(inverseFinalMatrix, tapCastEnd)
        msTapCastStart = msTapCastStart/msTapCastStart.w
        msTapCastEnd = msTapCastEnd/msTapCastEnd.w
        // decide whether intersects, same as raycasting method
        let TapCast = msTapCastEnd - msTapCastStart
        let Step = TapCast/2000
        var currentPosi = msTapCastStart
        // variable holding start and end
        var intersectionStart:simd_float4? = nil
        var lastIntersectionPosition:simd_float4? = nil
        var intersectionEnd:simd_float4? = nil
        var intersectionFlag:Bool = false
        for _ in 1...2000{
            if currentPosi[0]<1.0 && currentPosi[0]>(-1.0) && currentPosi[1]<1.0 && currentPosi[1]>(-1.0) && currentPosi[2]<1.0 && currentPosi[2]>(-1.0){
                //when intersect
                if intersectionFlag == false{
                    intersectionStart = currentPosi
                }
                intersectionFlag = true
                lastIntersectionPosition = currentPosi
                currentPosi += Step
                intersectionEnd = lastIntersectionPosition
            }else{
                if intersectionFlag == false{
                    lastIntersectionPosition = currentPosi
                    currentPosi += Step
                }else{
//                    intersectionEnd = currentPosi
                    break
                }
            }
        }
        if intersectionStart != nil && intersectionEnd != nil{
            return [intersectionStart!,intersectionEnd!]
        }else{
            return nil
        }
        
    }
    
    func graphDistance(from A:(Int,Int,Int),to B:(Int,Int,Int))->Float{
        let euclideanDistance = sqrt(pow(Double(abs(A.0-B.0)), 2) + pow(Double(abs(A.1-B.1)), 2) + pow(Double(abs(A.2-B.2)), 2))
        let intensityParameter = (intensity(for: A, lambda: 10) + intensity(for: B, lambda: 10))/2.0
        return Float(euclideanDistance) * intensityParameter
    }
    
    func intensity(for point:(Int,Int,Int), lambda:Float)->Float{
        let intensity = imageToDisplay.sample3Ddata(x: Float(point.0), y: Float(point.1), z: Float(point.2))
        let ratio = pow((1-(intensity - Float(imageToDisplay.minIntensity))/(Float(imageToDisplay.maxIntensity) - Float(imageToDisplay.minIntensity))),2)
        return Float(exp(ratio*lambda))
    }
    
    func nearPoints(around point:(Int,Int,Int))->[(Int,Int,Int)]{ // six points around a start point
        let array = [(-1,0,0),(0,-1,0),(0,0,-1),(1,0,0),(0,1,0),(0,0,1)]
        let pointArray = array.map({($0.0+point.0,$0.1+point.1,$0.2+point.2)})
        return pointArray.filter {space.isInSpace(point: $0)}
    }
    
    
    
    func smoothLine(line:[simd_float3],windowSize:Int)->[simd_float3]{
        if (windowSize < 2){return line}
        let length = line.count
        let halfWindowSize = Float(windowSize/2)
        let lineCopy = line
        var smoothedLine = lineCopy
        
        for i in 1..<line.count-1{
            var winC = [simd_float3]()
            var winW = [Float]()
            
            winC.append(lineCopy[i])
            winW.append(1.0 + halfWindowSize)
            
            for j in 1...Int(halfWindowSize){
                let k1 = max(0,min((i+j),length-1))
                let k2 = max(0,min((i-j),length-1))
                winC.append(contentsOf: [lineCopy[k1],lineCopy[k2]])
                winW.append(contentsOf: [1.0+halfWindowSize-Float(j),1.0+halfWindowSize-Float(j)])
            }
            
            var x:Float = 0.0,y:Float = 0.0,z:Float = 0.0,s:Float = 0.0
            for j in 0...winW.count-1{
                x += winW[j] * winC[j].x
                y += winW[j] * winC[j].y
                z += winW[j] * winC[j].z
                s += winW[j]
            }
            if s>0 {
                x /= s
                y /= s
                z /= s
            }
            
            smoothedLine[i] = simd_float3(x,y,z)
        }
        
        return smoothedLine
    }
}
