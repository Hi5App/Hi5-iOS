//
//  mySceneViewContrller.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.

import UIKit
import UniformTypeIdentifiers
import simd

class MarkerFactoryViewController: MetalViewController,MetalViewControllerDelegate,UIDocumentPickerDelegate {
 
    var worldModelMatrix:float4x4!
    var objectToDraw:Quad!{
        didSet{
            setupGestures()
            self.metalViewControllerDelegate = self
        }
    }
    var panSensivity:Float = 5.0
    var lastPanLocation:CGPoint!
    var imageToDisplay:image4DSimple!
    var scaleLabel:UIButton!
    var somaArray:[simd_float3] = [] // soma needs to be displayed
    var somaList:SomaListFeedBack!
    
    var user:User!
    var resUsed:String!
    var currentImageName:String = ""
    
    var somaPotentialLocation:PotentialLocationFeedBack!
    var brainListfeed:BrainListFeedBack!
    let perferredSize = 128
  
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        configureNavBar()
        self.view.backgroundColor = UIColor(red: 123.0/255.0, green: 133.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
        
        //request potential location and brainList for later use
        HTTPRequest.SomaPart.getPotentialLocation(name: user.userName, passwd: user.password) { feedback in
            if let feedback = feedback{
                self.somaPotentialLocation = feedback
//                print("first see potential location: \(self.somaPotentialLocation!)")
            }
        } errorHandler: { error in
            print("soma potential fetch failed")
        }
        HTTPRequest.ImagePart.getBrainList(name: user.userName, passwd: user.password) { feedback in
            if let feedback = feedback{
                self.brainListfeed = feedback
//                print("first see brainListFeedback: \(self.brainListfeed!)")
            }
        } errorHandler: { error in
            print("brain list fetch failed")
        }
    }
    // MARK: - Congfigue UI
    func configureButtons(){
        var backwardConfiguration = UIButton.Configuration.filled()
        backwardConfiguration.cornerStyle = .medium
        backwardConfiguration.baseBackgroundColor = UIColor(named: "mainOrange")
        backwardConfiguration.baseForegroundColor = UIColor(red: 123.0/255.0, green: 133.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        backwardConfiguration.buttonSize = .medium
        backwardConfiguration.title = "prev"
        backwardConfiguration.image = UIImage(systemName: "chevron.backward.square")
        backwardConfiguration.imagePlacement = .top
        
        var forwardConfiguration = backwardConfiguration
        forwardConfiguration.title = "next"
        forwardConfiguration.image = UIImage(systemName: "chevron.forward.square")
        
        let backwardButton = UIButton(configuration: backwardConfiguration)
        backwardButton.addTarget(self, action: #selector(backButtonTapped), for: .touchDown)
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        let forwardButton = UIButton(configuration: forwardConfiguration)
        backwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchDown)
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backwardButton)
        view.addSubview(forwardButton)
        
        // add scaleLabel
        var scaleLabelConfiguration = backwardConfiguration
        scaleLabelConfiguration.image = UIImage(systemName: "1.magnifyingglass")
        scaleLabelConfiguration.title = "  1.0x"
        scaleLabelConfiguration.imagePlacement = .leading
        scaleLabel = UIButton(configuration: scaleLabelConfiguration)
        scaleLabel.translatesAutoresizingMaskIntoConstraints = false
        scaleLabel.addTarget(self, action: #selector(resetScale), for: .touchUpInside)
        view.addSubview(scaleLabel)

        
        let constraints = [
            backwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            backwardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 5),
            forwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            forwardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -5),
            
            scaleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scaleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func configureNavBar(){
        navigationController?.navigationBar.tintColor = .label
        // bar colors
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "mainOrange")
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // buttons
        let readLocalFile = UIAction(title:"Local Image",image: UIImage(systemName: "folder.fill")){ (action) in
            self.readLocalImage()
        }
        let readCloudFile = UIAction(title:"Cloud Image",image: UIImage(systemName: "icloud.fill")){ (action) in
            self.readCloudImage()
        }
        let menu = UIMenu(title: "", options: .displayInline, children: [readLocalFile,readCloudFile])
        navigationItem.rightBarButtonItem = .init(systemItem: .add)
        navigationItem.rightBarButtonItem!.menu = menu
    }
    
    @objc func resetScale(){
        if let object = objectToDraw{
            object.scale = 1.0
            scaleLabel.configuration?.image = UIImage(systemName:"1.magnifyingglass")
            scaleLabel.setTitle("  1.0x", for: .normal)
        }
    }
    
    @objc func backButtonTapped(){
        
    }
    
    @objc func forwardButtonTapped(){
        
    }
    
   // MARK: - Image Reader
    func readLocalImage(){
        let v3drawUTType = UTType("com.penglab.Hi5-imageType.v3draw.v3draw")!
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [v3drawUTType])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func readCloudImage(){
        // check Guest Mode
        if user.email == "Guest@Guest.com"{
            
        }
        // send Request for Image
        guard somaPotentialLocation != nil && brainListfeed != nil else {
            // alert user for network issue
            return
        }
        
        for brainInfo in self.brainListfeed.barinList{
            if brainInfo.name == somaPotentialLocation!.image{
                let resArray = brainInfo.detail.components(separatedBy: ",")
                //trim res string
                let RIndex = resArray[1].firstIndex(of: "R") // use secondary resolution
                let endIndex = resArray[1].firstIndex(of: ")")
                self.resUsed = String(resArray[1][RIndex!...endIndex!])
                print(self.resUsed!)
            }
        }
        
        // download image and fetch somaList
        // test data 4433 / 2,13377 / 2,6692 / 2,191813，128
        HTTPRequest.ImagePart.downloadImage(centerX: somaPotentialLocation.loc.x, centerY: somaPotentialLocation.loc.y, centerZ: somaPotentialLocation.loc.z, size: perferredSize, res: self.resUsed, brainId: somaPotentialLocation.image, name: self.user.userName, passwd: self.user.password) { url in
            guard url != nil else {return}
            var PBDImage = PBDImage(imageLocation: url!) // decompress image
            self.imageToDisplay = PBDImage.decompressToV3draw()
            
            // request somaList
            HTTPRequest.SomaPart.getSomaList(centerX: self.somaPotentialLocation.loc.x, centerY: self.somaPotentialLocation.loc.y, centerZ: self.somaPotentialLocation.loc.z, size: self.perferredSize, res: self.resUsed, brainId: self.somaPotentialLocation.image, name: self.user.userName, passwd: self.user.password) { feedback in
                if let feedback = feedback{
                    self.somaList = feedback
                }
            } errorHandler: { error in
                print("soma List fetch failed")
            }

            
            //display image
            if let image = self.imageToDisplay{
                self.objectToDraw = Quad(device: self.device,commandQ: self.commandQueue,viewWidth: Int(self.view.bounds.width),viewHeight: Int(self.view.bounds.height),image4DSimple: image)
                // convert somaList data structure to somaArray model-space data structure
                
                // refresh existing soma
                self.somaArray.removeAll()
                //add soma
                
            }else{
                print("No 4d image")
            }
        } errorHandler: { error in
            print(error)
        }
            
        
//        HTTPRequest.ImagePart.getBrainList(name: user.userName, passwd: user.password) { brainListFeedback in
//            guard brainListFeedback != nil else{return}
//            self.brainListfeed = brainListFeedback!
//            for brainInfo in self.brainListfeed.barinList{
//                if brainInfo.name == "191813"{
//                    print(brainInfo.detail)
//                    let resArray = brainInfo.detail.components(separatedBy: ",")
//                    //trim string
//                    let RIndex = resArray[1].firstIndex(of: "R")
//                    let endIndex = resArray[1].firstIndex(of: ")")
//                    self.resUsed = String(resArray[1][RIndex!...endIndex!])
//                    print(self.resUsed!)
//
//                    // download image
//                    // test data 4433 / 2,13377 / 2,6692 / 2,191813，128
//                    HTTPRequest.ImagePart.downloadImage(centerX: 4433/2, centerY: 13377/2, centerZ: 6692/2, size: 128, res: self.resUsed, brainId: "191813", name: self.user.userName, passwd: self.user.password) { url in
//                        guard url != nil else {return}
//                        var PBDImage = PBDImage(imageLocation: url!)
//                        self.imageToDisplay = PBDImage.decompressToV3draw()
//
//                        //display image
//                        if let image = self.imageToDisplay{
//                            self.objectToDraw = Quad(device: self.device,commandQ: self.commandQueue,viewWidth: Int(self.view.bounds.width),viewHeight: Int(self.view.bounds.height),image4DSimple: image)
//                            self.somaArray.removeAll()
//                        }else{
//                            print("No 4d image")
//                        }
//
//                        // request somaList
//
//                    } errorHandler: { error in
//                        print(error)
//                    }
//                }
//            }
//        } errorHandler: { error in
//            // alert get barin list failed
//            print(error)
//            return
//        }
        
    }
    
    func readImageFromDocumentsFolder(filename:String){
        let fileManager = FileManager.default
        let reader = v3drawReader()
        let rawImage1Url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        imageToDisplay = reader.read(from: rawImage1Url)
        self.title = imageToDisplay.name
        
        // display image
        if let image = imageToDisplay{
            objectToDraw = Quad(device: device,commandQ: commandQueue,viewWidth: Int(view.bounds.width),viewHeight: Int(view.bounds.height),image4DSimple: image)
            somaArray.removeAll()
        }else{
            print("No 4d image")
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

  
  //MARK: - MetalViewControllerDelegate
    func renderObjects(drawable:CAMetalDrawable) {
    // draw the view
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil,somaArray:somaArray)
    }

    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
    }
    
    //MARK: - setup interaction with images
    func setupGestures(){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MarkerFactoryViewController.pan))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(MarkerFactoryViewController.pinch))
        let tap = UITapGestureRecognizer(target: self, action: #selector(MarkerFactoryViewController.tap))
        self.view.addGestureRecognizer(pan)
        self.view.addGestureRecognizer(pinch)
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func tap(tapGesture:UITapGestureRecognizer){
        if tapGesture.state == .ended{
            // calculate position in metal NDC
            let tapPosition = tapGesture.location(in: self.view)
            if let somaPosition = checkForIntersection(tapPosition){
                print("find soma at \(somaPosition)")
                somaArray.append(somaPosition)
            }
        }
    }
    
    func checkForIntersection(_ tapPosition:CGPoint)->simd_float3?{ //use to sample in the same time
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
        var currentIntensity:Float = 0
        var maxIntensity:Float = 0
        var maxPosition = currentPosi
        var flag = false
        for _ in 1...512{
            if currentPosi[0]<1.0 && currentPosi[0]>(-1.0) && currentPosi[1]<1.0 && currentPosi[1]>(-1.0) && currentPosi[2]<1.0 && currentPosi[2]>(-1.0){
                //when intersect
                flag = true
                currentIntensity = imageToDisplay.sample3Ddata(x: currentPosi.x, y: currentPosi.y, z: currentPosi.z)
                if currentIntensity > maxIntensity{
                    maxIntensity = currentIntensity
//                    print("maxIntensity changed to \(currentIntensity)")
                    maxPosition = currentPosi
                }
                currentPosi += Step
            }else{
                currentPosi += Step
            }
        }
        if flag{
            print("soma intensity is \(maxIntensity)")
            return simd_float3(maxPosition.x,maxPosition.y,maxPosition.z)
        }else{
            return nil
        }
    }
    
    @objc func pan(panGesture:UIPanGestureRecognizer){
        if panGesture.state == UIGestureRecognizer.State.changed{
            let pointInView = panGesture.location(in: self.view)
            
            let xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            let yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            objectToDraw.rotationY -= xDelta
            objectToDraw.rotationX -= yDelta
            lastPanLocation = pointInView
        }else if panGesture.state == UIGestureRecognizer.State.began{
            lastPanLocation = panGesture.location(in: self.view)
        }
    }
    
    var pinchScale:Float = 2.0
    @objc func pinch(pinchGesture:UIPinchGestureRecognizer){
        guard pinchGesture.view != nil else {return}
        if pinchGesture.state == .began || pinchGesture.state == .changed{
            if objectToDraw.scale >= 2 {
                objectToDraw.scale = 2
            }else if objectToDraw.scale <= 0.5 {
                objectToDraw.scale = 0.5
            }
            objectToDraw.scale = objectToDraw.scale * Float(pinchGesture.scale)
            pinchGesture.scale = 1.0
        }
        if pinchGesture.state == .ended{
            scaleLabel.setTitle(String(format: "  %.1fx", objectToDraw.scale), for: .normal)
            if objectToDraw.scale >= 1.0{
                scaleLabel.configuration?.image = UIImage(systemName: "plus.magnifyingglass")
            }else if objectToDraw.scale < 1.0{
                scaleLabel.configuration?.image = UIImage(systemName: "minus.magnifyingglass")
            }
        }
    }
}
