//
//  mySceneViewContrller.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.

import UIKit
import UniformTypeIdentifiers
import simd

class MarkerFactoryViewController:Image3dViewController{
    
    var timeoutNumber:Int = 0{
        didSet{
            if timeoutNumber > 5{
                OperationQueue.main.addOperation {
                    self.alertForNetworkError()
                }
            }
        }
    }
    
    var userPref:UserPreferences!
 
    //Buttons
    var backwardButton:UIButton!
    var forwardButton:UIButton!
    
    var isDownloading = false;
    var isWaiting = false;
    var DownloadThreadEnabled = false
    //Controls
    @IBOutlet var DoneButton: UIBarButtonItem!
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
    @IBOutlet var boringImageButton: UIBarButtonItem!
    @IBOutlet var goodImageButton: UIBarButtonItem!
    
    
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
    

//    let threadQueue = DispatchQueue.global()

    var preDownloadThread = Thread()
//    var checkFreshTimer = Timer()
    var checkDownloadTimer:Timer!

    // MARK: - Life Cycle
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageCache.imageCache.removeAll()
        checkDownloadTimer.invalidate()
//        checkFreshTimer.invalidate()
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
        self.preDownloadMethod()
//        checkFreshTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(checkFresh), userInfo: nil, repeats: true)
     
    }
    
    func alertForNetworkError(){
        if self.somaPotentialLocation == nil || self.brainListfeed == nil{
            let alert = UIAlertController(title: "Network Error", message: "Unable to request server image\nPlease try again later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel,handler: { (action) in
                self.checkDownloadTimer.invalidate()
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }

    override func renderObjects(drawable:CAMetalDrawable) {
    // draw the view
        markerArray = somaArray.map({ somaLoc in
            return Marker(type: .MarkerFactory, displayPosition: somaLoc, color: .systemOrange)
        })
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil, markerArray: markerArray, Tree: Tree,userLines: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        preDownloadThread.cancel()

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
        DoneButton.isEnabled = false
        boringImageButton.isEnabled = false
        goodImageButton.isEnabled = false
    }
    
    func enableButtons(){
        forwardButton.isEnabled = true
        backwardButton.isEnabled = true
        forwardButton.alpha = 1
        backwardButton.alpha = 1
        DoneButton.isEnabled = true
        boringImageButton.isEnabled = true
        goodImageButton.isEnabled = true
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
            mapToMarkerArray()
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
        disableButtons()
        if imageCache.previousOne() {
            self.somaPotentialLocation = self.imageCache.somaPoLocations[self.imageCache.index].potentialLocationFeedBack
            self.currentImageURL = self.imageCache.urls[self.imageCache.index]
            self.readLocalImage()
        }else{ //alert for no more files
            let alert = UIAlertController(title: "Sorry", message: "No more valid previous images", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (action) in
                self?.enableButtons()
            }))
            self.present(alert, animated: true)
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
            disableButtons()
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
        userArray.removeAll()
        originalSomaArray.removeAll()
        somaArray = userArray + originalSomaArray
        mapToMarkerArray()
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
    
    @IBAction func DoneButtonTapped(_ sender: Any) {
        let insertList = userArray.map { (somaLoc)->PositionFloat in
            return CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaLoc, center: self.somaPotentialSecondaryResLocation).loc
        }
        HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: 2, username: user.userName, passwd: user.password, insertSomaList: insertList, deleteSomaList: self.removeSomaArray) {
            print("soma marked as Done,add \(insertList.count) soma, delete \(self.removeSomaArray.count) soma")
            self.requestForNextImage()
            self.imageCache.somaPoLocations[self.imageCache.index].alreadyUpload = true
        } errorHandler: { error in
            print(error)
        }
    }
    
    @IBAction func BoringImageButtonTapped(_ sender: Any) {
        if userArray.isEmpty {
            imageCache.somaPoLocations[imageCache.index].isBoring = true
            HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: -1, username: user.userName, passwd: user.password, insertSomaList: [], deleteSomaList: self.removeSomaArray) {
                print("image marked as Trash")
                self.requestForNextImage()
                self.imageCache.somaPoLocations[self.imageCache.index].alreadyUpload = true
            } errorHandler: { error in
                print(error)
            }
        }else{
            // alert user for new soma data
            let alert = UIAlertController(title: "Attention", message: "Image marked as trash can't not have new soma marker,do you want to delete your soma marker?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel))
            alert.addAction(UIAlertAction(title: "Yes", style: .default,handler: { [self] (action) in
                self.userArray.removeAll()
                self.somaArray = originalSomaArray+userArray
            }))
            self.present(alert, animated: true)
            // check for next move
        }
    }
    
    @IBAction func GoodImageButtonTapped(_ sender: Any) {
        let insertList = userArray.map { (somaLoc)->PositionFloat in
            return CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaLoc, center: self.somaPotentialSecondaryResLocation).loc
        }
        HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: 3, username: user.userName, passwd: user.password, insertSomaList: insertList, deleteSomaList: self.removeSomaArray) {
            print("Image marked as Good,add \(insertList.count) soma, delete \(self.removeSomaArray.count) soma")
            self.requestForNextImage()
            self.imageCache.somaPoLocations[self.imageCache.index].alreadyUpload = true
        } errorHandler: { error in
            print(error)
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
                        self.DoneButton.isEnabled = true
                        self.goodImageButton.isEnabled = true
                        self.boringImageButton.isEnabled = true
                        
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
                if let image = self.imageToDisplay{
                    self.drawWithImage(image: image)
                }else{
                    print("No 4d image")
                }
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
                        self.showMessage(message: self.currentImageName,showProcess: false)
                        self.DoneButton.isEnabled = true
                        self.goodImageButton.isEnabled = true
                        self.boringImageButton.isEnabled = true
                        
                        self.enableButtons()
                        
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
        self.imageToDisplay.make3DArrayFrom1DArray()
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
                    self.somaArray =  self.originalSomaArray + self.userArray
//                    print(somaArray)
                }
                
            }else if editStatus == .Delete{ // delete mode
                // detect possible soma
                if let somaPostion = findSomaLocation(tapPosition, deleteMode: true){
                    print("find existing soma at \(somaPostion),removed it")
                    // refresh from somaArray
                    if let removeIndex = userArray.firstIndex(of: somaPostion){
                        print(removeIndex)
                        userArray.remove(at: removeIndex)
                        somaArray = originalSomaArray + userArray
                        mapToMarkerArray()
                    }else if let removeIndex = originalSomaArray.firstIndex(of: somaPostion){
                        print(removeIndex)
                        originalSomaArray.remove(at: removeIndex)
                        somaArray = originalSomaArray + userArray
                        mapToMarkerArray()
                    }
                    // add to remove list
                    let soma = CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaPostion, center: self.somaPotentialSecondaryResLocation)
                    guard self.somaList != nil else {return}
                    for somaInfo in self.somaList.somaList{
                        if (somaInfo.loc.x - soma.loc.x)<0.1 && (somaInfo.loc.y - soma.loc.y)<0.1 && (somaInfo.loc.z - soma.loc.z)<0.1{
                            self.removeSomaArray.append(somaInfo.id) // add to removeList
                            print("soma with name \(somaInfo.id) add to remove list")
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Pre download
    @objc func preDownloadMethod() {
        checkDownloadTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(preLoad), userInfo: nil, repeats: true)
        
    }
    
    @objc func preLoad(){
//        print("download checked")
        if (preDownloadThread.isCancelled) {
            Thread.exit()
        }
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
                            self.timeoutNumber += 1
                            print(error)
                        }
                    }
                }
            } errorHandler: { error in
                print(error)
                self.timeoutNumber += 1
                if (error == "Empty") {
                    print("No more file")
                }
                self.isDownloading = false
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
    
    @objc func checkFresh() {
        if (self.imageCache.index < 0) {
            return
        }
        let curPotentialLocation = self.imageCache.somaPoLocations[self.imageCache.index]
        if (somaPotentialLocation != nil && !curPotentialLocation.alreadyUpload && !self.imageCache.ifStillFresh(tempIndex: self.imageCache.index)) {
            let expiredAlert = UIAlertController(title: "Attention", message: "Current file is expired, will change another file for you.", preferredStyle: .alert )
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { action in
                self.requestForNextImage()
            }
            expiredAlert.addAction(confirmAction)
            self.present(expiredAlert, animated: true)
        }
    }
}
