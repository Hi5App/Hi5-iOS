//
//  CheckModeViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/13.
//

import Foundation

import UIKit
import UniformTypeIdentifiers
import simd

class CheckModeViewController:Image3dViewController{
 
    //Buttons
    var backwardButton:UIButton!
    var forwardButton:UIButton!
    
    var isDownloading = false;
    var isWaiting = false;
    var DownloadThreadEnabled = false
    //mode switcher
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
    // color buttons
    var markerColor:UIColor = UIColor.systemOrange
    var currentMarkerType:MarkerType = .MarkerFactory
    @IBOutlet var redPenButton: UIBarButtonItem!
    @IBOutlet var bluePenButton: UIBarButtonItem!
    @IBOutlet var yellowPenButton: UIBarButtonItem!
    
    @IBAction func changeToRed(_ sender:UIBarButtonItem){
        changeMarkerColor(to: UIColor.systemRed, withType: .WrongMarker, sender: sender)
    }
    
    @IBAction func changeToBlue(_ sender:UIBarButtonItem){
        changeMarkerColor(to: UIColor.systemBlue, withType: .MissingMarker, sender: sender)
    }
    
    @IBAction func changeToYellow(_ sender:UIBarButtonItem){
        changeMarkerColor(to: UIColor.systemYellow, withType: .BreakingPointMarker, sender: sender)
    }
    
    func changeMarkerColor(to color:UIColor,withType type:MarkerType, sender:UIBarButtonItem){
        // clear choosen button state
        redPenButton.image = UIImage(systemName: "pencil.circle")
        bluePenButton.image = UIImage(systemName: "pencil.circle")
        yellowPenButton.image = UIImage(systemName: "pencil.circle")
        // set new state
        sender.image = UIImage(systemName: "pencil.circle.fill")
        // set new color
        markerColor = color
        currentMarkerType = type
    }
    
    // type buttons
    @IBOutlet var GoodTypeButton: UIBarButtonItem!
    @IBOutlet var SWCBadButton: UIBarButtonItem!
    @IBOutlet var NormalButton: UIBarButtonItem!
    @IBOutlet var ImageBadButton: UIBarButtonItem!
    
    @IBAction func GoodTypeTapped(_ sender: Any) {
        
    }
    
    @IBAction func swcBadTapped(_ sender: Any) {
        
    }
    
    @IBAction func normalTypeTapped(_ sender: Any) {
        
    }
    
    @IBAction func ImageBadTapped(_ sender: Any) {
        
    }
    
    
    
    var somaPotentialLocation:PotentialLocationFeedBack!{
        didSet{
            somaPotentialSecondaryResLocation = PositionInt(x: somaPotentialLocation.loc.x/2,
                                                            y: somaPotentialLocation.loc.y/2,
                                                            z: somaPotentialLocation.loc.z/2)
            
        }
    }
    
    var somaPotentialSecondaryResLocation:PositionInt!
    var imageCache:image4DSimpleCache!
    var brainListfeed:BrainListFeedBack!
    var somaList:SomaListFeedBack!
    var resUsed:String!
    
    let threadQueue = DispatchQueue.global()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageCache.imageCache.removeAll()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        // hide label
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
        imageCache = image4DSimpleCache()
//        request potential location and brainList for later use

//        HTTPRequest.ImagePart.getBrainList(name: user.userName, passwd: user.password) { feedback in
//            if let feedback = feedback{
//                self.brainListfeed = feedback
//                print("brainList")
//                HTTPRequest.SomaPart.getPotentialLocation(name: self.user.userName, passwd: self.user.password) { feedback in
//                    if let feedback = feedback{
//
//                        self.somaPotentialLocation = feedback
//
//                        print("first see potential location: \(self.somaPotentialLocation!)")
//                        self.imageCache.addLocation(location: feedback)
//
//
//                    }
//                } errorHandler: { error in
//                    alertForNetworkError()
//                    print("soma potential fetch failed")
//                }
//            }
//        } errorHandler: { error in
//            alertForNetworkError()
//            print("brain list fetch failed")
//        }
        if !DownloadThreadEnabled {
            DownloadThreadEnabled = true
            threadQueue.async {
                self.preDownloadMethod()
            }
        }
        
        func alertForNetworkError(){
            if self.somaPotentialLocation == nil || self.brainListfeed == nil{
                let alert = UIAlertController(title: "Network Error", message: "Unable to request server image\nPlease try again later", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel,handler: { (action) in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    override func renderObjects(drawable: CAMetalDrawable) {
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil, markerArray: markerArray, Tree: Tree)
    }
    
    // MARK: - Congfigue UI
    
    func configureButtons(){
        var backwardConfiguration = UIButton.Configuration.filled()
        backwardConfiguration.cornerStyle = .medium
        backwardConfiguration.baseBackgroundColor = UIColor(named: "mainOrange")
        backwardConfiguration.baseForegroundColor = UIColor.label
        backwardConfiguration.buttonSize = .medium
        backwardConfiguration.title = "prev"
        backwardConfiguration.image = UIImage(systemName: "chevron.backward.square")
        backwardConfiguration.imagePlacement = .top
        
        var forwardConfiguration = backwardConfiguration
        forwardConfiguration.title = "next"
        forwardConfiguration.image = UIImage(systemName: "chevron.forward.square")
        
        backwardButton = UIButton(configuration: backwardConfiguration)
        backwardButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton = UIButton(configuration: forwardConfiguration)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backwardButton)
        view.addSubview(forwardButton)
        
        let constraints = [
            backwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            backwardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 5),
            forwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            forwardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -5)
        ]
        NSLayoutConstraint.activate(constraints)
        
        disableButtons()
    }
    
    func disableButtons(){
        forwardButton.isEnabled = false
        backwardButton.isEnabled = false
        forwardButton.alpha = 0
        backwardButton.alpha = 0
    }
    
    func enableButtons(){
        forwardButton.isEnabled = true
        backwardButton.isEnabled = true
        forwardButton.alpha = 1
        backwardButton.alpha = 1
    }
    
    override func configureNavBar(){
        super.configureNavBar()
        // buttons
        let openImageButton = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.down"), style: .plain, target: self, action: #selector(requestForNextImage))
        
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
        }
    }
    
    @objc func backButtonTapped(){
        // update soma list
        if !userArray.isEmpty || !removeSomaArray.isEmpty{
            let insertList = userArray.map { (somaLoc)->PositionFloat in
                return CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaLoc, center: self.somaPotentialSecondaryResLocation).loc
            }
            HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: 1, username: user.userName, passwd: user.password, insertSomaList: insertList, deleteSomaList: self.removeSomaArray) {
                print("soma List uploaded successfully,add \(insertList.count) soma, delete \(self.removeSomaArray.count) soma")
                self.imageCache.somaPoLocations[self.imageCache.index].alreadyUpload = true
            } errorHandler: { error in
                print(error)
            }
        }
        // retrive soma locaiton from cache
//        if let location = imageCache.previousLocation(){
//            self.somaPotentialLocation = location
//            readCloudImage()
//        }
        if imageCache.previousOne() {
            self.somaPotentialLocation = self.imageCache.somaPoLocations[self.imageCache.index].potentialLocationFeedBack
            self.currentImageURL = self.imageCache.urls[self.imageCache.index]
        }
    }
    
    @objc func forwardButtonTapped(){
        // update soma list
        if !userArray.isEmpty || !removeSomaArray.isEmpty{
            let insertList = userArray.map { (somaLoc)->PositionFloat in
                return CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaLoc, center: self.somaPotentialSecondaryResLocation).loc
            }
            HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: 1, username: user.userName, passwd: user.password, insertSomaList: insertList, deleteSomaList: self.removeSomaArray) {
                print("soma List uploaded successfully,add \(insertList.count) soma, delete \(self.removeSomaArray.count) soma")
                self.requestForNextImage()
                self.imageCache.somaPoLocations[self.imageCache.index].alreadyUpload = true
            } errorHandler: { error in
                print(error)
            }
        }else{
            self.requestForNextImage()
        }
    }
    
    // delete PBD image files to free app storage
    func deletePBDImageCache(){
        // delete current local image
        let fileManager = FileManager.default
        do{
            if let url = self.currentImageURL{
                try fileManager.removeItem(at: url)
            }
        }catch{
            print("delete cache image failed")
        }
    }
    
    @objc func requestForNextImage(){
//        userArray.removeAll()
//        somaArray = userArray + originalSomaArray
        
        // try retrive images from cache
//        if let location = imageCache.nextLocation(){
//            self.somaPotentialLocation = location
//            self.readCloudImage()
//        }else{
//            // request image from server
//            HTTPRequest.SomaPart.getPotentialLocation(name: user.userName, passwd: user.password) { feedback in
//                if let feedback = feedback{
//                    self.somaPotentialLocation = feedback
//                    print("forward see potential location: \(self.somaPotentialLocation!)")
//                    self.imageCache.addLocation(location: feedback)
//                    self.readCloudImage()
//                }
//            } errorHandler: { error in
//                print("soma potential fetch failed")
//            }
//        }
        if imageCache.nextOne() {
            self.somaPotentialLocation = imageCache.somaPoLocations[imageCache.index].potentialLocationFeedBack
            self.currentImageURL = imageCache.urls[imageCache.index]
            self.readLocalImage()
        } else {
            isWaiting = true
            self.showMessage(message: "Downloading...",showProcess: true)
            self.disableButtons()
            self.perform(#selector(timeOutHandler), with: nil, afterDelay: 30)
        }
    }
    
    @objc func timeOutHandler() {
        if isWaiting {
            self.showMessage(message: self.currentImageName, showProcess: false)
            isWaiting = false
            self.enableButtons()
        }
    }
    
   // MARK: - Image Reader
    
    @objc func readCloudImage(){
        // check Guest Mode
        if user.email == "Guest@Guest.com"{
            let alert = UIAlertController(title: "Attention", message: "You are currently in Guest Mode\nGuest can not request for server image, please sign in to continue", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            return
        }
        // check location and brainList
        guard somaPotentialLocation != nil && brainListfeed != nil else {
            // alert user for network issue
            return
        }
        
        // get secondary resolution
        for brainInfo in self.brainListfeed.brainList{
            if brainInfo.name == somaPotentialLocation!.image{
                let resArray = brainInfo.detail.components(separatedBy: ",")
                //trim res string
                let RIndex = resArray[1].firstIndex(of: "R") // use secondary resolution
                let endIndex = resArray[1].firstIndex(of: ")")
                self.resUsed = String(resArray[1][RIndex!...endIndex!])
//                print(self.resUsed!)
            }
        }
        showMessage(message: "Downloading...",showProcess: true)
        disableButtons()
        
        // download image and fetch somaList
        HTTPRequest.ImagePart.downloadImage(
            centerX: somaPotentialSecondaryResLocation.x,
            centerY: somaPotentialSecondaryResLocation.y,
            centerZ: somaPotentialSecondaryResLocation.z,
            size: perferredSize,
            res: self.resUsed,
            brainId: somaPotentialLocation.image,
            name: self.user.userName,
            passwd: self.user.password) { url in
            guard url != nil else {return}
            var PBDImage = PBDImage(imageLocation: url!) // decompress image
            self.currentImageURL = url
            self.showMessage(message: "Decompressing...",showProcess: true)
            self.imageToDisplay = PBDImage.decompressToV3draw()
//            self.deletePBDImageCache() //delete PBDimage file after decompress
            // request somaList
            HTTPRequest.SomaPart.getSomaList(centerX: self.somaPotentialLocation.loc.x, centerY: self.somaPotentialLocation.loc.y, centerZ: self.somaPotentialLocation.loc.z, size: self.somaperferredSize, res:"", brainId: self.somaPotentialLocation.image, name: self.user.userName, passwd: self.user.password) { feedback in
                if let feedback = feedback{
                    print(feedback)
                    self.somaList = feedback
                    // save to cache
                    self.originalSomaArray = self.somaList.somaList.map({ (somaInfo)->simd_float3 in
                        return CoordHelper.UploadSomaLocation2DisplaySomaLocation(uploadLoc: somaInfo, center: self.somaPotentialSecondaryResLocation)
                    })
                    self.userArray.removeAll()
                    //display image
                    if let image = self.imageToDisplay{
                        self.showMessage(message: self.currentImageName,showProcess: false)
                        
                        self.drawWithImage(image: image)
                        self.enableButtons()
                    }else{
                        print("No 4d image")
                    }
                }
            } errorHandler: { error in
                print("soma List fetch failed")
            }
        } errorHandler: { error in
            print(error)
        }
    }
    
    func readLocalImage() {
        self.showMessage(message: "Decompressing...",showProcess: true)
        DispatchQueue.global(qos: .userInitiated).async {
            self.decompressImage {
                // request somaList
                HTTPRequest.SomaPart.getSomaList(centerX: self.somaPotentialLocation.loc.x, centerY: self.somaPotentialLocation.loc.y, centerZ: self.somaPotentialLocation.loc.z, size: self.somaperferredSize, res:"", brainId: self.somaPotentialLocation.image, name: self.user.userName, passwd: self.user.password) { feedback in
                    if let feedback = feedback{
                        print(feedback)
                        self.somaList = feedback
                        // save to cache
                        self.originalSomaArray = self.somaList.somaList.map({ (somaInfo)->simd_float3 in
                            return CoordHelper.UploadSomaLocation2DisplaySomaLocation(uploadLoc: somaInfo, center: self.somaPotentialSecondaryResLocation)
                        })
                        self.userArray.removeAll()
                        //display image
                        if let image = self.imageToDisplay{
                            self.showMessage(message: self.currentImageName,showProcess: false)
                            self.drawWithImage(image: image)
                            self.enableButtons()
                        }else{
                            print("No 4d image")
                        }
                    }
                } errorHandler: { error in
                    print("soma List fetch failed")
                }
            }
        }
    }
    
    
    func decompressImage(completion:()->()){
        var PBDImage = PBDImage(imageLocation: self.currentImageURL!) // decompress image
        self.imageToDisplay = PBDImage.decompressToV3draw()
        completion()
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
    
    @objc override func tap(tapGesture:UITapGestureRecognizer){
        if tapGesture.state == .ended{
            // check for markType
            if currentMarkerType == .MarkerFactory{
                let alert = UIAlertController(title: "Which Marker Type?", message: "Please choose a marker type below", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel,handler:nil))
                self.present(alert, animated: true)
                return 
            }
            
            // check for mode
            let tapPosition = tapGesture.location(in: self.view)
            
            if editStatus == .View || editStatus == .Mark{
                // normal mark mode
                editStatus = .Mark
                respondEditStatusChange()
                // calculate position in metal NDC
                if let somaPosition = findSomaLocation(tapPosition,deleteMode: false){
                    print("find soma at \(somaPosition)")
                    userArray.append(somaPosition)
                    markerArray.append(Marker(type: currentMarkerType, displayPosition: somaPosition, color: markerColor))
                    self.somaArray =  self.originalSomaArray + self.userArray
//                    print(somaArray)
                }
                
            }else if editStatus == .Delete{ // delete mode
                // detect possible soma
                if let somaPostion = findSomaLocation(tapPosition, deleteMode: true){
                    print("find existing soma at \(somaPostion),removed it")
                    // refresh from somaArray
                    for marker in markerArray{
                        if marker.displayPosition == somaPostion{
                            markerArray = markerArray.filter{ $0 != marker}
                        }
                    }
                }
            }
        }
    }
    
    func preDownloadMethod() {
        while (true) {
            if (imageCache.somaPoLocations.count - imageCache.index < 7 && !isDownloading) {
                self.isDownloading = true
                HTTPRequest.SomaPart.getPotentialLocation(name: user.userName, passwd: user.password) { potentialLocationFeedback in
                    if let potentialLocationFeedback = potentialLocationFeedback {
//                        self.imageCache.addLocation(location: potentialLocationFeedback)
                        
                        if let _ = self.brainListfeed {
                            self.downloadImage(potentialLocationFeedback: potentialLocationFeedback)
                        } else {
                            HTTPRequest.ImagePart.getBrainList(name: self.user.userName, passwd: self.user.password) { feedback in
                                if let feedback = feedback {
                                    self.brainListfeed = feedback
                                    self.downloadImage(potentialLocationFeedback: potentialLocationFeedback)
                                }
                            } errorHandler: { error in
                                print(error)
                            }
                        }
                    }
                } errorHandler: { error in
                    print("Error")
                }

            }
        }
    }
    
    func downloadImage(potentialLocationFeedback:PotentialLocationFeedBack) {
        var resUsed = ""
        
        for brainInfo in self.brainListfeed.brainList{
            if brainInfo.name == potentialLocationFeedback.image{
                let resArray = brainInfo.detail.components(separatedBy: ",")
                //trim res string
                let RIndex = resArray[1].firstIndex(of: "R") // use secondary resolution
                let endIndex = resArray[1].firstIndex(of: ")")
                resUsed = String(resArray[1][RIndex!...endIndex!])
            }
        }
        HTTPRequest.ImagePart.downloadImage(centerX: potentialLocationFeedback.loc.x / 2, centerY: potentialLocationFeedback.loc.y / 2, centerZ: potentialLocationFeedback.loc.z / 2, size: self.perferredSize, res: resUsed, brainId: potentialLocationFeedback.image, name: self.user.userName, passwd: self.user.password) { url in
            if let url = url{
                self.imageCache.addLocation(location: potentialLocationFeedback, url:url)
                self.isDownloading = false
                if self.isWaiting {
                    self.isWaiting = false
                    let _ = self.imageCache.nextOne()
                    self.somaPotentialLocation = self.imageCache.somaPoLocations[self.imageCache.index].potentialLocationFeedBack
                    self.currentImageURL = self.imageCache.urls[self.imageCache.index]
                    self.readLocalImage()
                    
                }
            }
        } errorHandler: { error in
            self.isDownloading = false
        }
    }
}
