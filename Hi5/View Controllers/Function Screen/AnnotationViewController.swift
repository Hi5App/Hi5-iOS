//
//  AnnotationViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/29.
//

import UIKit
import UniformTypeIdentifiers
import simd

struct intersectionSpace{
    var x0:Float
    var x1:Float
    var y0:Float
    var y1:Float
    var z0:Float
    var z1:Float
    
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
    
    func isInSpace(point:simd_float4)->Bool{
        return point.x >= x0 && point.x <= x1 && point.y >= y0 && point.y <= y1 && point.z >= z0 && point.z <= z1
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
    
    @IBAction func Tracing(_ sender: Any) {
    }
    
    @IBAction func moreOptions(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
    }
    
    var userPref:UserPreferences!
    var space:intersectionSpace!
    
    // MARK: - Congfigue UI
    override func configureNavBar(){
        super.configureNavBar()
        // buttons
        let readLocalFile = UIAction(title:"Local Image",image: UIImage(systemName: "folder.fill")){ (action) in
            self.readLocalImage()
        }
        let menu = UIMenu(title: "", options: .displayInline, children: [readLocalFile])
        let openImageButton = UIBarButtonItem(systemItem: .add)
        openImageButton.menu = menu
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
        }
    }
    
   // MARK: - Image Reader
    func readLocalImage(){
        let v3drawUTType = UTType("com.penglab.Hi5-imageType.v3draw.v3draw")!
        let swcUTType = UTType("com.penglab.Hi5-annotationType.swc")!
        let pbdUTType = UTType("com.penglab.Hi5-imageType.pbd")!
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [v3drawUTType,swcUTType,pbdUTType])
//        let documentPicker = UIDocumentPickerViewController()
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func readImageFromDocumentsFolder(filename:String){
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
//                    print(space)
                }
            }else if panGesture.state == UIGestureRecognizer.State.ended{
                print(touchPoints)
                print(space)
                // calculate curve
                let startRay = touchPoints.prefix(2)
                let endRay = touchPoints.suffix(2)
                print(space.isInSpace(point: startRay[0]))
                // reset space
                space = nil
                touchPoints = []
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
        let Step = TapCast/512
        var currentPosi = msTapCastStart
        // variable holding start and end
        var intersectionStart:simd_float4? = nil
        var intersectionEnd:simd_float4? = nil
        var intersectionFlag:Bool = false
        for _ in 1...512{
            if currentPosi[0]<1.0 && currentPosi[0]>(-1.0) && currentPosi[1]<1.0 && currentPosi[1]>(-1.0) && currentPosi[2]<1.0 && currentPosi[2]>(-1.0){
                //when intersect
                if intersectionFlag == false{
                    intersectionStart = currentPosi
                }
                intersectionFlag = true
                currentPosi += Step
            }else{
                if intersectionFlag == false{
                    currentPosi += Step
                }else{
                    intersectionEnd = currentPosi
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
}
