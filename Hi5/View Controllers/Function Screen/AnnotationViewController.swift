//
//  AnnotationViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/29.
//

import UIKit
import UniformTypeIdentifiers
import simd

class AnnotationViewController:Image3dViewController,UIDocumentPickerDelegate{
    
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
    override func viewDidLoad() {
        super.viewDidLoad()
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(0.0, y: 0.0, z: 0.0)
        
    }
    
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
}
