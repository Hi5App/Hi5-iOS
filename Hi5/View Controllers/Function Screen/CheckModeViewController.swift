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

enum ReconstructionType:Int {
    case Good = 4
    case BadSwcGoodImage = 3
    case NormalSwcNormalImage = 2
    case BadImage = -1
}

struct arborFeedbackManagement{
    var currentFeedback:QueryArborFeedBack
    var downloadStatus:[URL?]{
        didSet{
            let indicatorArray = downloadStatus.map { item in
                return item == nil ? 0 : 1
            }
            print(indicatorArray)
//            print("download \(downloadStatus.count) images")
        }
    }
    var nextFeedback:QueryArborFeedBack?
    
    func getPosition(at currentFeedbackIndex:Int) -> ArborInfo{
        return currentFeedback.arbors[currentFeedbackIndex]
    }
}

class CheckModeViewController:Image3dViewController,passUserPrefChange{
 
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
    // tool bars
    @IBOutlet var markToolbar: UIToolbar!
    @IBOutlet var swcTypeToolbar: UIToolbar!
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
        self.editStatus = .Mark
        self.respondEditStatusChange()
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
    
    // track daily soma
    var userPref:UserPreferences!{
        didSet{
//            print(userPref)
            achievementChecker = AchievementChecker(dailySomaGoal: userPref.dailySomaGoal, dailyCheckGoal: userPref.dailyCheckGoal, pastAchievement: userPref.achievements)
//            print(achievementChecker)
        }
    }
    var achievementChecker:AchievementChecker?
    
    
    @IBAction func GoodTypeTapped(_ sender: Any) {
        uploadImageResults(resultNumber: 4, resultType: "Good")
        forwardButtonTapped()
    }
    
    @IBAction func swcBadTapped(_ sender: Any) {
        uploadImageResults(resultNumber: 3, resultType: "swc Bad")
        forwardButtonTapped()
    }
    
    @IBAction func normalTypeTapped(_ sender: Any) {
        uploadImageResults(resultNumber: 2, resultType: "Normal")
        forwardButtonTapped()
    }
    
    @IBAction func ImageBadTapped(_ sender: Any) {
        uploadImageResults(resultNumber: -1, resultType: "Bad")
        forwardButtonTapped()
    }
    
    func uploadImageResults(resultNumber:Int,resultType:String){
        HTTPRequest.QualityInspectionPart.updateSingleArborResult(arborId: currentArbor.id, result: resultNumber, name: self.user.userName, passwd: self.user.password) { [self] in
            print("image marked as \(resultType)")
            userPref.dailyCheck += 1
            print(userPref.dailyCheck)
            userPref.totalCheck += 1
            if let type = achievementChecker?.check(dailySoma: userPref.dailySoma, dailyCheck: userPref.dailyCheck, totalSoma: userPref.totalSoma, totalCheck: userPref.totalCheck){
                userPref.achievements = achievementChecker!.pastAchievement
                showAchievements(for: type, with: userPref.dailyCheckGoal)
            }
        } errorHandler: { error in
            print("error")
        }
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
    
    var getArborFeedBack:arborFeedbackManagement!
    var currentFeedbackIndex = 0
    var currentArbor:ArborInfo!
    var currentMarkerFeedBack:QueryMarkerListFeedBack!
    var currentFormerResults:QueryArborFormerResults!
    var emptyTree:neuronTree? = nil
    var cacheTree:neuronTree?
    var showingSWC:Bool = false{
        didSet{
            if showingSWC {
                if let tree = cacheTree{
                    self.Tree = tree
                }
            } else{
                cacheTree = self.Tree
                self.Tree = emptyTree
            }
        }
    }
    
    var checkTimer:Timer = Timer()
    
    var t1:Date!
    var t2:Date!
    
    var delegate:passUserPrefChange!
    //MARK: - Lifecycle
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageCache.imageCache.removeAll()
        uploadMarkerArray()
        uploadDeleteMarkerArray()
        delegate.userPref = userPref
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
        imageCache = image4DSimpleCache()
        // down brainlist
        HTTPRequest.ImagePart.getBrainList(name: self.user.userName, passwd: self.user.password) { feedback in
            if let feedback = feedback {
                self.brainListfeed = feedback
                // download arbor
                HTTPRequest.QualityInspectionPart.getArbor(name: self.user.userName, passwd: self.user.password) { feedback in
                    if let feed = feedback{
//                        print(feed)
                        
                        self.getArborFeedBack = arborFeedbackManagement(currentFeedback: feed,downloadStatus: Array(repeating: nil, count: feed.arbors.count))
                        self.currentArbor = feed.arbors[0]
                        // debug
                        self.readCloudImage()
                        self.downloadImages()
                    }
                } errorHandler: { error in
                    print(error)
                }
            }
        } errorHandler: { error in
            print(error)
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
        
        // adjust swc switch constraint
        swcSwitch.alpha = 1
        swcSwitch.isEnabled = false
        showingSWC = false
        let bottomConstraint = swcSwitch.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -(markToolbar.frame.height+swcTypeToolbar.frame.height+CGFloat(20)))
        NSLayoutConstraint.activate([bottomConstraint])
        swcSwitch.addTarget(self, action: #selector(toggleSWC), for: .touchUpInside)
        
        //show label for former result
        formerArborResult.alpha = 1
        formerArborResult.setTitle("No Results", for: .normal)
        let fbottomConstraint = formerArborResult.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -(markToolbar.frame.height+swcTypeToolbar.frame.height+CGFloat(20)))
        NSLayoutConstraint.activate([fbottomConstraint])
        formerArborResult.addTarget(self, action: #selector(showFormerResults), for: .touchUpInside)
        
        //debug show achievment
//        showAchievements(for: .total1000Soma, with: 100)
    }
    
    
    
    @objc func toggleSWC(){
        if showingSWC {
            showingSWC = false
            swcSwitch.configuration?.image = UIImage(systemName: "eye.slash.fill")
        }else{
            showingSWC = true
            swcSwitch.configuration?.image = UIImage(systemName: "eye.fill")
        }
    }
    
    @objc func showFormerResults(){
        let vc = FormerResultsController(results: currentFormerResults)
        vc.title = "Results"
        let nav = UINavigationController(rootViewController: vc)

        let DoneButton = UIBarButtonItem(systemItem: .done, primaryAction: .init(handler: { _ in
            vc.dismiss(animated: true)
        }), menu: nil)
        vc.navigationItem.rightBarButtonItem = DoneButton
        vc.navigationController?.navigationBar.prefersLargeTitles = true
        
        if let sheet = nav.sheetPresentationController{
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(nav, animated: true)
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
        // other buttons
        GoodTypeButton.isEnabled = false
        SWCBadButton.isEnabled = false
        formerArborResult.isEnabled = false
        NormalButton.isEnabled = false
        ImageBadButton.isEnabled = false
        swcSwitch.isEnabled = false
    }
    
    func enableButtons(){
        forwardButton.isEnabled = true
        backwardButton.isEnabled = true
        forwardButton.alpha = 1
        backwardButton.alpha = 1
        GoodTypeButton.isEnabled = true
        SWCBadButton.isEnabled = true
        NormalButton.isEnabled = true
        ImageBadButton.isEnabled = true
        swcSwitch.isEnabled = true
        formerArborResult.isEnabled = true
    }
    
    override func configureNavBar(){
        super.configureNavBar()
        // buttons
//        let openImageButton = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.down"), style: .plain, target: self, action: #selector(readCloudImage))
        
        let UndoButton = UIBarButtonItem()
        UndoButton.image = UIImage(systemName: "arrow.counterclockwise")
        UndoButton.target = self
        UndoButton.action = #selector(undoAMarker)
        navigationItem.rightBarButtonItems = [UndoButton]
    }
    
    @objc func undoAMarker(){
        if !markerArray.isEmpty{
            markerArray.remove(at: markerArray.count-1)
        }
    }
    
    @objc func backButtonTapped(){
        // update soma list
        uploadMarkerArray()
        uploadDeleteMarkerArray()
        // change index and require image
        handleArborFeedback(direction: 0)
        readCloudImage()
    }
    
    @objc func forwardButtonTapped(){
        // record time
        t1 = Date()
        // update soma list
        showMessage(message: "Uploading Marker...", showProcess: true)
        uploadMarkerArray()
        uploadDeleteMarkerArray()
        // change index and require image
        handleArborFeedback(direction: 1)
        readCloudImage()
    }
    
    func handleArborFeedback(direction:Int){ // direction 1 = forward  / 0 = backward
        // check for arbor status
        if direction == 1{
            currentFeedbackIndex += 1
        }else if direction == 0{
            if currentFeedbackIndex != 0{
                currentFeedbackIndex -= 1
            }
        }
        if currentFeedbackIndex >= 5 && getArborFeedBack.nextFeedback == nil{
            print("reach threshold")
            HTTPRequest.QualityInspectionPart.getArbor(name: self.user.userName, passwd: self.user.password) { feedback in
                if let feed = feedback{
                    self.getArborFeedBack.nextFeedback = feed
                    print("next feedback download success")
                }
            } errorHandler: { error in
                print(error)
            }
        }
        if currentFeedbackIndex > 9{
            currentFeedbackIndex = 0
            if let feed = getArborFeedBack.nextFeedback{
                getArborFeedBack.currentFeedback = feed
                getArborFeedBack.downloadStatus = Array(repeating: nil, count: feed.arbors.count)
                downloadImages()
            }else{
                //TODO: alert user for no more arbor feedback
            }
            getArborFeedBack.nextFeedback = nil
        }
        print("index now is \(currentFeedbackIndex)")
        currentArbor = getArborFeedBack.getPosition(at: currentFeedbackIndex)
    }
    
    func uploadMarkerArray(){
        if !markerArray.isEmpty{
            let insertMarkerList = markerArray.map { (marker) -> ArborDetail in
                switch marker.type{
                case .MissingMarker:
                    return ArborDetail(arborId: currentArbor.id, loc: CoordHelper.DisplayMarkerLocation2GlobalLocation(from: marker.displayPosition, center: self.centerPosition), type: 3)
                case .WrongMarker:
                    return ArborDetail(arborId: currentArbor.id, loc: CoordHelper.DisplayMarkerLocation2GlobalLocation(from: marker.displayPosition, center: self.centerPosition), type: 2)
                case .BreakingPointMarker:
                    return ArborDetail(arborId: currentArbor.id, loc: CoordHelper.DisplayMarkerLocation2GlobalLocation(from: marker.displayPosition, center: self.centerPosition), type: 6)
                default:
                    fatalError("unknown mark type")
                }
            }
            HTTPRequest.QualityInspectionPart.insertMarkerList(insertMarkerList: insertMarkerList, name: self.user.userName, passwd: self.user.password) {
                print("\(insertMarkerList.count) markers uploaded")
            } errorHandler: { error in
                print(error)
            }
        }
    }
    
    func uploadDeleteMarkerArray(){
        if !deleteMarkerIndexArray.isEmpty{
            HTTPRequest.QualityInspectionPart.deleteMarkerList(name: self.user.userName, passwd: self.user.password, deleteMarkerList: deleteMarkerIndexArray) {
                print("\(self.deleteMarkerIndexArray.count) markers were deleted")
                self.deleteMarkerIndexArray.removeAll()
            } errorHandler: { error in
                print(error)
            }

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
        self.Tree = nil
        disableButtons()
        
        showMessage(message: "Downloading Image...", showProcess: true)
        // search image and swc
        checkTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(checkForExistingImage), userInfo: nil, repeats: true)
    }
    
    @objc func checkForExistingImage(){
        if let url = getArborFeedBack.downloadStatus[currentFeedbackIndex] {
            print("image download")
            self.currentImageURL = url
            checkTimer.invalidate()
            showMessage(message: "Decompressing image...", showProcess: true)
            self.decompressImage{
                if let image = imageToDisplay{
                    drawWithImage(image: image)
                }else{
                    print("No 4d image")
                }
                let queue = DispatchQueue.global()
                queue.async {
                    self.imageToDisplay.make3DArrayFrom1DArray()
                }
//            request swc
                 HTTPRequest.QualityInspectionPart.getSwc(
                     centerX: currentArbor.loc.x,
                     centerY: currentArbor.loc.y,
                     centerZ: currentArbor.loc.z,
                     size: self.somaperferredSize,
                     imageId: currentArbor.image,
                     somaId: currentArbor.somaId,
                     arborName: currentArbor.name,
                     name: self.user.userName,
                     passwd: self.user.password) { [self] url in
                         if let url = url{
                             Tree = neuronTree(from: url)
                             showingSWC = true
                             swcSwitch.configuration?.image = UIImage(systemName: "eye.fill")
                             if let branches = Tree?.organizeBranch(){
                                 Tree?.branchIndexes = branches
                             }else{
                                 fatalError("Neuron Tree Fail to init")
                             }
                             print("init swc")
                             showMessage(message: "Request Marker...", showProcess: true)
                             HTTPRequest.QualityInspectionPart.queryMarkerList(arborId: currentArbor.id, name: self.user.userName, passwd: self.user.password) { [self] feedback in
                                 if let feed = feedback{
                                     print(feed)
                                     self.currentMarkerFeedBack = feed
                                     self.markerArray = feed.markerList.map({ item in
                                         switch item.type{
                                         case 3:
                                             return Marker(type: .MissingMarker, displayPosition: CoordHelper.swcPointsLocation2DisplayLineLocation(from: item.loc, swcCenter: self.centerPosition), color: .systemBlue)
                                         case 2:
                                             return Marker(type: .WrongMarker, displayPosition: CoordHelper.swcPointsLocation2DisplayLineLocation(from: item.loc, swcCenter: self.centerPosition), color: .systemRed)
                                         case 6:
                                             return Marker(type: .BreakingPointMarker, displayPosition: CoordHelper.swcPointsLocation2DisplayLineLocation(from: item.loc, swcCenter: self.centerPosition), color: .systemYellow)
                                         default:
                                             fatalError("unknown marker type")
                                         }
                                     })
                                     self.originalSomaArray = self.markerArray.map({ marker in
                                         return simd_float3(x: marker.displayPosition.x, y: marker.displayPosition.y, z: marker.displayPosition.z)
                                     })
                                     
                                     // query former results
                                     HTTPRequest.QualityInspectionPart.queryArborsResult(arborId: self.currentArbor.id, name: self.user.userName, passwd: self.user.password) { [self] feedback in
                                         if let feed = feedback{
                                             if feed.formerResults.count > 0{
                                                 self.currentFormerResults = feed
                                                 formerArborResult.setTitle("\(feed.formerResults.count) Former Results", for: .normal)
                                                 formerArborResult.configuration?.image = UIImage(systemName: "bag.fill")
                                             }
                                         }
                                     } errorHandler: { error in
                                         print(error)
                                     }


                                     showMessage(message: self.currentImageName, showProcess: false)
                                     t2 = Date()
                                     if t1 != nil{
                                         print("times used: " + String(format: "%.2f", t2.timeIntervalSince(t1)))
                                     }
                                     enableButtons()
                                     
                                     
                                 }
                             } errorHandler: { error in
                                 print(error)
                             }
                         }
                     } errorHandler: { error in
                         print("error in get swc")
                         print(error)
                     }
            }
//
        }else{
            print("waiting")
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
    
    func downloadImages(){
        
        // check for arbor
        if getArborFeedBack == nil || self.brainListfeed == nil{
            // alert user
            return
        }
        
        // get secondary resolution
        for brainInfo in self.brainListfeed.brainList{
            if brainInfo.name == currentArbor.image{
                let resArray = brainInfo.detail.components(separatedBy: ",")
                //trim res string
                let RIndex = resArray[1].firstIndex(of: "R") // use secondary resolution
                let endIndex = resArray[1].firstIndex(of: ")")
                self.resUsed = String(resArray[1][RIndex!...endIndex!])
            }
        }
        
        for arbor in getArborFeedBack.currentFeedback.arbors{
            HTTPRequest.ImagePart.downloadImage(
                centerX: Int(arbor.loc.x)/2,
                centerY: Int(arbor.loc.y)/2,
                centerZ: Int(arbor.loc.z)/2,
                size: perferredSize,
                res: self.resUsed,
                brainId: arbor.image,
                name: self.user.userName,
                passwd: self.user.password){ url in
//                    print("file \(String(describing: url)) downloaded successfully")
                    if let index = self.getArborFeedBack.currentFeedback.arbors.firstIndex(of:arbor){
                        self.getArborFeedBack.downloadStatus[index] = url
                    }
                }errorHandler: { error in
                    print(error)
                }
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
            // check for markType
            
            
            // check for mode
            let tapPosition = tapGesture.location(in: self.view)
            
            if editStatus == .View || editStatus == .Mark{
                if currentMarkerType == .MarkerFactory{
                    let alert = UIAlertController(title: "Which Marker Type?", message: "Please choose a marker type below", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel,handler:nil))
                    self.present(alert, animated: true)
                    return
                }
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
                    // get delete soma id in feedback
                    let position = CoordHelper.DisplayMarkerLocation2GlobalLocation(from: somaPostion, center: Tree!.centerPosition)
                    if let feed = self.currentMarkerFeedBack{
                        if !feed.markerList.isEmpty{
                            let id = feed.markerList.filter({
                                abs($0.loc.x - position.x) < 1 && abs($0.loc.y - position.y) < 1 && abs($0.loc.z - position.z) < 1
                            })[0].id
                            deleteMarkerIndexArray.append(id)
                        }
                    }
                    originalSomaArray = originalSomaArray.filter({$0 != somaPostion})
                    userArray = userArray.filter({$0 != somaPostion})
                    self.somaArray =  self.originalSomaArray + self.userArray
                    markerArray = markerArray.filter({$0.displayPosition != somaPostion})
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
