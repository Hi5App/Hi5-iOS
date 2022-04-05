//
//  mySceneViewContrller.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.

import UIKit
import UniformTypeIdentifiers

class MySceneViewController: MetalViewController,MetalViewControllerDelegate,UIDocumentPickerDelegate {
  
    var worldModelMatrix:Matrix4!
    var objectToDraw:Quad!
    var panSensivity:Float = 120.0
    var lastPanLocation:CGPoint!
    var imageToDisplay:image4DSimple!
    var scaleLabel:UIButton!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        addLabelView()
        self.view.backgroundColor = UIColor(red: 123.0/255.0, green: 133.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        worldModelMatrix = Matrix4()
        worldModelMatrix.translate(x:0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAround(x:20.0, y: -25.0, z: 0.0)
    }
    
    func configureNavBar(){
        navigationController?.navigationBar.tintColor = .label
        // bar colors
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemOrange
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(chooseAndReadImage))
    }
    
    func addLabelView(){
        scaleLabel = UIButton(type: .system)
        scaleLabel.setTitle("Scale:1.0", for: .normal)
        scaleLabel.setTitleColor(UIColor.systemBlue, for: .normal)
        scaleLabel.backgroundColor = UIColor.systemOrange
        scaleLabel.translatesAutoresizingMaskIntoConstraints = false
        scaleLabel.layer.cornerRadius = 4.0
        scaleLabel.addTarget(self, action: #selector(resetScale), for: .touchUpInside)
        view.addSubview(scaleLabel)

        let constraints = [
            scaleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scaleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func resetScale(){
        objectToDraw.scale = 1.0
        scaleLabel.setTitle("Scale:1.0", for: .normal)
    }
    
   // MARK: - Image Reader
    @objc func chooseAndReadImage(){
        let v3drawUTType = UTType("com.penglab.Hi5-imageType.v3draw.v3draw")!
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [v3drawUTType])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
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
                    try fileManager.copyItem(at: url, to: appFolderDocumentURL)
                }
            }catch{
                print(error)
            }
            
            // read the selected image from document folder
            let reader = v3drawReader()
            let rawImage1Url = appFolderDocumentURL
            imageToDisplay = reader.read(from: rawImage1Url)
            self.title = imageToDisplay.name
            
            // display image
            if let image = imageToDisplay{
                objectToDraw = Quad(device: device,commandQ: commandQueue,viewWidth: Int(view.bounds.width),viewHeight: Int(view.bounds.height),image4DSimple: image)
            }else{
                print("No 4d image")
            }
            self.metalViewControllerDelegate = self
            setupGestures()
            
            url.stopAccessingSecurityScopedResource()
        }
    }

  
  //MARK: - MetalViewControllerDelegate
    func renderObjects(drawable:CAMetalDrawable) {
    // draw the view
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
    }

    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
    }
    
    //MARK: - setup interaction with images
    func setupGestures(){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MySceneViewController.pan))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(MySceneViewController.pinch))
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
            scaleLabel.setTitle(String(format: "Scale:%.1f", objectToDraw.scale), for: .normal)
            print("pinchScale \(pinchGesture.scale)")
            print("objectScale \(objectToDraw.scale)")
        }
    }
  
  
}
