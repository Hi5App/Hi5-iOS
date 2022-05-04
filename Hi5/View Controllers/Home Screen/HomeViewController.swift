//
//  ViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/2/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

protocol checkLoginStatus{
    var loginStatus:Bool{get set}
}

class HomeViewController: UIViewController,checkLoginStatus{
    
    var loginStatus: Bool = true{
        didSet{
            if loginStatus == false{
                backToLogin()
            }
        }
    }
    
    @IBOutlet var functionCollectionView: UICollectionView!
    let functionDataSource = functionCollectionViewDataSource()
    var loginUser:User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(named: "homeBackground")
        configureNavBar()
        functionCollectionView.dataSource = functionDataSource
        functionCollectionView.delegate = self
        configureCollectionViewLayout()
        
        // for debug
//        showMarkerFactory()
    }
    
    func configureCollectionViewLayout(){
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.frame.size.width/2.4), height: (view.frame.size.height/4))
        layout.minimumLineSpacing = 20
        layout.scrollDirection = .vertical
        layout.sectionInset.left = 15
        layout.sectionInset.right = 15
        layout.sectionInset.top = 25
        layout.sectionInset.bottom = 10
        functionCollectionView.collectionViewLayout = layout
    }
    
    func configureNavBar(){
        self.title = "Home"
        navigationController?.navigationBar.tintColor = .label
        // bar colors
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "mainOrange")
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .done,
            target: self,
            action: #selector(tapUser))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .done,
            target: self,
            action: nil)
    }
    
    @objc func tapUser(){
        if loginUser.email == "Guest@Guest.com"{
            let alert = UIAlertController(title: "Attention", message: "You are currently in Guest Mode\nSign in to see account infomation", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Sign in", style: .default,handler: { (action) in
                //present loginViewController
                self.backToLogin()
            }))
            self.present(alert, animated: true)
            return
        }else{
            let UserInfoVC = UserInfoViewController(style: .insetGrouped)
            UserInfoVC.loginUser = self.loginUser
            UserInfoVC.delagate = self
            self.present(UserInfoVC, animated: true)
        }
    }
    
    func backToLogin(){
        self.navigationController?.popViewController(animated: true)
    }
}

extension HomeViewController:UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch functionDataSource.softwareFunctions[indexPath.row].name{
        case "Marker Factory":
            showMarkerFactory()
        case "Annotation":
            showAnnotation()
        default:
            let alert = UIAlertController(title: "Sorry", message: "This function is currently unavailable", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    func showMarkerFactory(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MarkFactoryVC") as! MarkerFactoryViewController
        nextViewController.user = self.loginUser
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func showAnnotation(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AnnoVC") as! AnnotationViewController
        nextViewController.user = self.loginUser
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}
