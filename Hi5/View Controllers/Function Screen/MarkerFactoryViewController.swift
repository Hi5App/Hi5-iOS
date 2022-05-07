//
//  mySceneViewContrller.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.

import UIKit
import UniformTypeIdentifiers
import simd

class MarkerFactoryViewController:Image3dViewController{
 
    //Buttons
    var backwardButton:UIButton!
    var forwardButton:UIButton!
    
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
        
        
        HTTPRequest.ImagePart.getBrainList(name: user.userName, passwd: user.password) { feedback in
            if let feedback = feedback{
                self.brainListfeed = feedback
                print("brainList")
                HTTPRequest.SomaPart.getPotentialLocation(name: self.user.userName, passwd: self.user.password) { feedback in
                    if let feedback = feedback{
                        
                        self.somaPotentialLocation = feedback
                        
                        print("first see potential location: \(self.somaPotentialLocation!)")
                        self.imageCache.addLocation(location: feedback)
                        
                        
                    }
                } errorHandler: { error in
                    alertForNetworkError()
                    print("soma potential fetch failed")
                }
            }
        } errorHandler: { error in
            alertForNetworkError()
            print("brain list fetch failed")
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
        let openImageButton = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.down"), style: .plain, target: self, action: #selector(readCloudImage))
        
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
            } errorHandler: { error in
                print(error)
            }
        }
        // retrive soma locaiton from cache
        if let location = imageCache.previousLocation(){
            self.somaPotentialLocation = location
            readCloudImage()
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
    
    func requestForNextImage(){
//        userArray.removeAll()
//        somaArray = userArray + originalSomaArray
        
        // try retrive images from cache
        if let location = imageCache.nextLocation(){
            self.somaPotentialLocation = location
            self.readCloudImage()
        }else{
            // request image from server
            HTTPRequest.SomaPart.getPotentialLocation(name: user.userName, passwd: user.password) { feedback in
                if let feedback = feedback{
                    self.somaPotentialLocation = feedback
                    print("forward see potential location: \(self.somaPotentialLocation!)")
                    self.imageCache.addLocation(location: feedback)
                    self.readCloudImage()
                }
            } errorHandler: { error in
                print("soma potential fetch failed")
            }
        }
    }
    
    @IBAction func DoneButtonTapped(_ sender: Any) {
        let insertList = userArray.map { (somaLoc)->PositionFloat in
            return CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaLoc, center: self.somaPotentialSecondaryResLocation).loc
        }
        HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: 2, username: user.userName, passwd: user.password, insertSomaList: insertList, deleteSomaList: self.removeSomaArray) {
            print("soma marked as Done,add \(insertList.count) soma, delete \(self.removeSomaArray.count) soma")
            self.requestForNextImage()
        } errorHandler: { error in
            print(error)
        }
    }
    
    @IBAction func BoringImageButtonTapped(_ sender: Any) {
        if userArray.isEmpty {
            HTTPRequest.SomaPart.updateSomaList(imageId: self.somaPotentialLocation.image, locationId:self.somaPotentialLocation.id, locationType: -1, username: user.userName, passwd: user.password, insertSomaList: [], deleteSomaList: self.removeSomaArray) {
                print("image marked as Trash")
                self.requestForNextImage()
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
        
        // get secondary resolution
        for brainInfo in self.brainListfeed.barinList{
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
            print("Image Downloaded successfully\nDecompress Image...")
            var PBDImage = PBDImage(imageLocation: url!) // decompress image
            self.currentImageURL = url
                self.showMessage(message: "Decompressing...",showProcess: true)
            self.imageToDisplay = PBDImage.decompressToV3draw()
            print("Image Decompressed successfully")
            self.deletePBDImageCache() //delete PBDimage file after decompress
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
                    print(somaArray)
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
                    }else if let removeIndex = originalSomaArray.firstIndex(of: somaPostion){
                        print(removeIndex)
                        originalSomaArray.remove(at: removeIndex)
                        somaArray = originalSomaArray + userArray
                    }
                    // add to remove list
                    let soma = CoordHelper.DisplaySomaLocation2UploadSomaLocation(displayLoc: somaPostion, center: self.somaPotentialSecondaryResLocation)
                    guard self.somaList != nil else {return}
                    for somaInfo in self.somaList.somaList{
                        if (somaInfo.loc.x - soma.loc.x)<0.1 && (somaInfo.loc.y - soma.loc.y)<0.1 && (somaInfo.loc.z - soma.loc.z)<0.1{
                            self.removeSomaArray.append(somaInfo.name) // add to removeList
                            print("soma with name \(somaInfo.name) add to remove list")
                        }
                    }
                }
            }
        }
    }
}
