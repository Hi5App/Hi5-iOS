//
//  Image3dViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/29.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import simd

enum editMode:String{
    case View = "View"
    case Mark = "Mark"
    case Delete = "Delete"
}

class Image3dViewController: MetalViewController,MetalViewControllerDelegate{
    
    var worldModelMatrix:float4x4!
    var objectToDraw:Quad!{
        didSet{
            setupGestures()
            self.metalViewControllerDelegate = self
        }
    }
    
    var editStatus:editMode = .View
    var scaleLabel:UIButton!
    var indicator:UIButton!
    var swcSwitch:UIButton!
    
    var userArray:[simd_float3] = [] // soma marked by user
    var originalSomaArray:[simd_float3] = [] // soma list fetched from server
    var removeSomaArray:[Int] = [] // somaInfo name removed by user
    var somaArray:[simd_float3] = [] // soma needs to be displayed
    var markerArray:[Marker] = []
    var deleteMarkerIndexArray:[Int] = []
    
    var panSensivity:Float = 5.0
    var lastPanLocation:CGPoint!
    var imageToDisplay:image4DSimple!
    
    var user:User!
    var currentImageName:String = ""
    var currentImageURL:URL!{
        didSet{
            currentImageName = self.trimFromPbdFilename(from: currentImageURL.lastPathComponent)
        }
    }
    var localImageURL:URL!
    
    var centerPosition:PositionFloat!
    var Tree:neuronTree?{
        didSet{
            if let Tree = Tree {
                centerPosition = Tree.centerPosition
            }
        }
    }
    var swcLineArray:[simd_float3] = []
    
    let perferredSize = 128
    let somaperferredSize = 256
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLabels()
        configureNavBar()
        self.view.backgroundColor = UIColor(red: 123.0/255.0, green: 133.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
    }
    
    func drawWithImage(image:image4DSimple){
        self.objectToDraw = Quad(device: self.device,commandQ: self.commandQueue,viewWidth: Int(self.view.bounds.width)*Int(UIScreen.main.scale),viewHeight: Int(self.view.bounds.height)*Int(UIScreen.main.scale),image4DSimple: image)
        // refresh existing soma
        self.somaArray.removeAll()
        // convert somaList data structure to somaArray model-space data structure
        self.somaArray =  self.originalSomaArray + self.userArray
    }
    // MARK: - Congfigue UI
    
    func configureLabels(){
        var backwardConfiguration = UIButton.Configuration.filled()
        backwardConfiguration.cornerStyle = .medium
        backwardConfiguration.baseBackgroundColor = UIColor(named: "mainOrange")
        backwardConfiguration.baseForegroundColor = UIColor.label
        backwardConfiguration.buttonSize = .medium
        backwardConfiguration.title = "prev"
        backwardConfiguration.image = UIImage(systemName: "chevron.backward.square")
        backwardConfiguration.imagePlacement = .top
        
        // add scaleLabel
        var scaleLabelConfiguration = backwardConfiguration
        scaleLabelConfiguration.image = UIImage(systemName: "1.magnifyingglass")
        scaleLabelConfiguration.title = "  1.0x"
        scaleLabelConfiguration.imagePlacement = .leading
        scaleLabel = UIButton(configuration: scaleLabelConfiguration)
        scaleLabel.translatesAutoresizingMaskIntoConstraints = false
        scaleLabel.addTarget(self, action: #selector(resetScale), for: .touchUpInside)
        view.addSubview(scaleLabel)
        
        // add Indicator Label
        var indicatorLabelConfiguration = scaleLabelConfiguration
        indicatorLabelConfiguration.image = nil
        indicatorLabelConfiguration.imagePadding = 8
        indicatorLabelConfiguration.showsActivityIndicator = false
        indicatorLabelConfiguration.title = "No Image"
        indicator = UIButton(configuration: indicatorLabelConfiguration)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        
        // add swc switch
        var swcSwitchConfiguration = scaleLabelConfiguration
        swcSwitchConfiguration.image = UIImage(systemName: "eye.fill")
        swcSwitchConfiguration.imagePadding = 10
        swcSwitchConfiguration.title = "Show swc"
        swcSwitch = UIButton(configuration: swcSwitchConfiguration)
        swcSwitch.translatesAutoresizingMaskIntoConstraints = false
        swcSwitch.alpha = 0
        swcSwitch.isEnabled = false
        view.addSubview(swcSwitch)
        
        
        let constraints = [
            scaleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scaleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            indicator.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 10),
            indicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            swcSwitch.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 10),
//            swcSwitch.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -100)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func hideMessageLabel(){
        indicator.alpha = 0
    }
    
    func showMessage(message:String,showProcess show:Bool){
        indicator.setTitle(message,for: .normal)
        indicator.configuration?.showsActivityIndicator = show
    }
    
    @objc func resetScale(){
        if let object = objectToDraw{
            object.scale = 1.0
            scaleLabel.configuration?.image = UIImage(systemName:"1.magnifyingglass")
            scaleLabel.setTitle("  1.0x", for: .normal)
        }
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
    }
    
    func trimFromPbdFilename(from pbdFileName:String)->String{
        var imageName = pbdFileName
        let resStart = imageName.firstIndex(of: "_")!
        let resEnd = imageName.secondIndex(of: "_")!
        imageName.removeSubrange(resStart..<resEnd)
        imageName.removeLast(7)
        return imageName
    }
    
   // MARK: - Image Reader
    // define in sub-class

  
  //MARK: - MetalViewControllerDelegate
    func renderObjects(drawable:CAMetalDrawable) {
    // draw the view
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil, markerArray: markerArray, Tree: Tree)
    }

    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
    }
    
    //MARK: - setup interaction with images
    
    
    func respondEditStatusChange(){
        // define in subclass
    }
    
    func setupGestures(){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MarkerFactoryViewController.pan))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(MarkerFactoryViewController.pinch))
        let tap = UITapGestureRecognizer(target: self, action: #selector(MarkerFactoryViewController.tap))
        self.view.addGestureRecognizer(tap)
        self.view.addGestureRecognizer(pan)
        self.view.addGestureRecognizer(pinch)
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
            if editStatus == .Mark{
                editStatus = .View
                respondEditStatusChange()
            }
            lastPanLocation = panGesture.location(in: self.view)
        }
    }
    
    var pinchScale:Float = 2.0
    @objc func pinch(pinchGesture:UIPinchGestureRecognizer){
        guard pinchGesture.view != nil else {return}
        if pinchGesture.state == .began || pinchGesture.state == .changed{
            if editStatus == .Mark{
                editStatus = .View
                respondEditStatusChange()
            }
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
    
    @objc func tap(tapGesture:UITapGestureRecognizer){
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
                    }
                }
            }
        }
    }
    
    func findSomaLocation(_ tapPosition:CGPoint,deleteMode:Bool)->simd_float3?{ //use to sample in the same time
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
                if !deleteMode {
                    currentIntensity = imageToDisplay.sample3Ddata(x: currentPosi.x, y: currentPosi.y, z: currentPosi.z)
                    if currentIntensity > maxIntensity{
                        maxIntensity = currentIntensity
    //                    print("maxIntensity changed to \(currentIntensity)")
                        maxPosition = currentPosi
                    }
                }else{
                    for somaPosi in self.somaArray{
                        let distance = simd_distance(somaPosi,simd_float3(currentPosi.x,currentPosi.y,currentPosi.z))
                        if distance < 0.1{
                            return somaPosi
                        }
                    }
                }
                currentPosi += Step
            }else{
                currentPosi += Step
            }
        }
        if flag && !deleteMode{
            print("soma intensity is \(maxIntensity)")
            return simd_float3(maxPosition.x,maxPosition.y,maxPosition.z)
        }else{
            return nil
        }
    }
}
