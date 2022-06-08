//
//  UserDetailViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/6/7.
//

import UIKit

class UserDetailViewController: UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    var loginUser:User!
    var options:[option]!
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    
    @IBOutlet var totalCheckLabel: UILabel!
    @IBOutlet var dailyCheckLabel: UILabel!
    @IBOutlet var totalSomaCheck: UILabel!
    @IBOutlet var dailySomaCheck: UILabel!
    
    @IBOutlet var actionTableView: UITableView!
    
    @IBOutlet var signOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOptions()
        actionTableView.dataSource = self
        actionTableView.delegate = self
        actionTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        requestForNumberCounts()
        fillLabels()
        tapImageGesture()
        profileImageView.layer.cornerRadius = 40
    }
    
    func requestForNumberCounts(){
        
    }
    
    func fillLabels(){
        userNameLabel.text = loginUser.userName
        emailLabel.text = loginUser.email
    }
    
    func fillCounts(checkNumber:Int,DCheckNumber:Int,somaNumber:Int,DSomaNumber:Int){
        totalCheckLabel.text = String(checkNumber)
        dailyCheckLabel.text = String(DCheckNumber)
        totalSomaCheck.text = String(somaNumber)
        dailySomaCheck.text = String(DSomaNumber)
    }
    
    func tapImageGesture(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(changeGender))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func changeGender(){
        let actionsheet = UIAlertController(title: "Choose your gender", message: nil, preferredStyle: .actionSheet)
        let manChoice = UIAlertAction(title: "Male", style: .default) { _ in
            self.profileImageView.image = UIImage(named: "man")
        }
        let womanChoice = UIAlertAction(title: "Female", style: .default) { _ in
            self.profileImageView.image = UIImage(named: "woman")
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionsheet.addAction(manChoice)
        actionsheet.addAction(womanChoice)
        actionsheet.addAction(cancel)
        self.present(actionsheet, animated: true)
    }
    
    
    // MARK: - table view setup
    struct option{
        let title:String
        let description:String
        let imageName:String
    }
    
    func setupOptions(){
        options = [
            option(title: "Daily Goals", description: "", imageName: "flag"),
            option(title: "Leaderboard", description: "", imageName: "person"),
            option(title: "Achievements", description: "", imageName: "star.circle")
        ]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row].title
        cell.imageView?.image = UIImage(systemName: options[indexPath.row].imageName)
        cell.backgroundColor = UIColor(named: "cellBackground")
        return cell
    }

}
