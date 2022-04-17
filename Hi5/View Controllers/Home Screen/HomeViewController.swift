//
//  ViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/2/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class HomeViewController: UIViewController{
    
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
        let UserInfoVC = UserInfoViewController(style: .insetGrouped)
        UserInfoVC.loginUser = self.loginUser
        self.present(UserInfoVC, animated: true)
    }
}

extension HomeViewController:UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch functionDataSource.softwareFunctions[indexPath.row].name{
        case "Marker Factory":
            showMarkerFactory()
        default:
            print("function not available")
        }
    }
    
    func showMarkerFactory(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "mysceneviewcontroller") as! MySceneViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}
