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

protocol passUserPrefChange{
    var userPref:UserPreferences!{get set}
}

class HomeViewController: UIViewController,checkLoginStatus,passUserPrefChange{
    
    var loginStatus: Bool = true{
        didSet{
            if loginStatus == false{
                backToLogin()
            }
        }
    }
    
    @IBOutlet var functionCollectionView: UICollectionView!
    let functionDataSource = functionCollectionViewDataSource()
    var loginUser:User!{
        didSet{
            if userPref == nil{
                let achievements = AchievementRecord(dailySomaReached: false, dailyCheckReached: false,
                                                     somaBronzeMedal: false,
                                                     checkBronzeMedal: false,
                                                     somaSliverMedal: false,
                                                     checkSlivereMedal: false,
                                                     somaGoldMedal: false,
                                                     checkGoldMedal: false, dailyGoalTimeStamp: Date())
                userPref = UserPreferences(username: loginUser.userName, password: loginUser.password, autoLogin: false, ImageShapening: false,genderPicture: true,achievements: achievements)
            }
        }
    }
    var userPref:UserPreferences!{
        didSet{
//            print(userPref)
            saveUserPref()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(named: "homeBackground")
        userPref.achievements.refreshDailyGoal()
        configureNavBar()
        functionCollectionView.dataSource = functionDataSource
        functionCollectionView.delegate = self
        configureCollectionViewLayout()
        saveUserPref()
    }
    
    func saveUserPref(){
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("userPref.plist"){
            do{
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(userPref)
                try data.write(to: documentURL,options: .atomic)
//                print(userPref)
                print("user pref saved in home screen")
            }catch{
                print("user pref save in home screen failed")
            }
        }
    }
    
    func loadUserPref(){
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("userPref.plist"){
            do{
                let data = try Data(contentsOf: documentURL)
                let unarchiver = PropertyListDecoder()
                userPref = try unarchiver.decode(UserPreferences.self, from: data)
                print("user pref loaded in home screen")
            }catch{
                print("user pref load in home screen failed")
            }
        }
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
            action: #selector(tapSettings))
    }
    
    @objc func tapSettings(){
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
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "settingVC") as! SettingTableViewController
            nextViewController.delegate = self
            nextViewController.userPref = self.userPref
            self.navigationController?.pushViewController(nextViewController, animated: true)
        }
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
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "userDetailVC") as! UserDetailViewController
            nextViewController.delegate = self
            nextViewController.loginDelagate = self
            nextViewController.loginUser = self.loginUser
            nextViewController.userPref = self.userPref
            self.navigationController?.pushViewController(nextViewController, animated: true)
        }
    }
    
    func backToLogin(){
        userPref.username = ""
        userPref.password = ""
        userPref.autoLogin = false
        saveUserPref()
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
        case "Check":
            showCheck()
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
        nextViewController.userPref = self.userPref
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func showAnnotation(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AnnoVC") as! AnnotationViewController
        nextViewController.user = self.loginUser
        nextViewController.imageSharpen = self.userPref.ImageShapening
        nextViewController.userPref = self.userPref
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func showCheck(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "checkVC") as! CheckModeViewController
        nextViewController.user = self.loginUser
        nextViewController.imageSharpen = self.userPref.ImageShapening
        nextViewController.userPref = self.userPref
        nextViewController.delegate = self
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}
