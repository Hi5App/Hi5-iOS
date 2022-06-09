//
//  UserDetailViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/6/7.
//

import UIKit

class UserDetailViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,passUserPrefChange{
    
    var loginUser:User!
    var userPref:UserPreferences!
    var options:[option]!
    
    var delegate:passUserPrefChange!
    
    var loginDelagate:checkLoginStatus?
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    
    @IBOutlet var totalCheckLabel: UILabel!
    @IBOutlet var dailyCheckLabel: UILabel!
    @IBOutlet var totalSomaCheck: UILabel!
    @IBOutlet var dailySomaCheck: UILabel!
    
    @IBOutlet var actionTableView: UITableView!
    
    @IBOutlet var signOutButton: UIButton!
    
    @IBAction func signOut(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        self.loginDelagate?.loginStatus = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        if self.loginDelagate?.loginStatus != false {
            delegate.userPref = self.userPref
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOptions()
        actionTableView.dataSource = self
        actionTableView.delegate = self
        actionTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        fillLabels()
        requestForNumberCounts()
        tapImageGesture()
        
        //use userPref
        setupProfileImage()
        updateDailySomaGoal(goal: userPref.dailyGoals)
        profileImageView.layer.cornerRadius = 40
    }
    
    func setupProfileImage(){
        if userPref.genderPicture{
            profileImageView.image = UIImage(named: "man")
        }else{
            profileImageView.image = UIImage(named: "woman")
        }
    }
    
    func requestForNumberCounts(){
        HTTPRequest.UserPart.queryPerformance(name: loginUser.userName, passwd: loginUser.password) { [self] feedback in
            if let feed = feedback{
                fillCounts(checkNumber: feed.totalCheck, DCheckNumber: feed.dailyCheck, somaNumber: feed.totalsoma, DSomaNumber: feed.dailysoma)
                updateDailySomaGoal(goal: userPref.dailyGoals)
            }
        } errorHandler: { error in
            print(error)
        }

    }
    
    func fillLabels(){
        userNameLabel.text = loginUser.userName
        emailLabel.text = loginUser.email
        fillCounts(checkNumber: 0, DCheckNumber: 0, somaNumber: 0, DSomaNumber: 0)
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
            self.userPref.genderPicture = true
        }
        let womanChoice = UIAlertAction(title: "Female", style: .default) { _ in
            self.profileImageView.image = UIImage(named: "woman")
            self.userPref.genderPicture = false
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionsheet.addAction(manChoice)
        actionsheet.addAction(womanChoice)
        actionsheet.addAction(cancel)
        self.present(actionsheet, animated: true)
    }
    
    func updateDailySomaGoal(goal:Int){
        if goal <= 0{
            return
        }else{
            dailySomaCheck.text = "0/\(goal)"
            userPref.dailyGoals = goal
        }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let title = options[indexPath.row].title
        switch title{
        case "Daily Goals":
            let inputView = UIAlertController(title: "Set your daily Goals", message: nil, preferredStyle: .alert)
            
            inputView.addTextField { textfield in
                textfield.placeholder = "Your daily soma Goal"
                textfield.keyboardType = .numberPad
            }
            
            inputView.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                let text = inputView.textFields![0].text!
                print("goal is \(text)")
                if let goal = Int(text){
                    self.updateDailySomaGoal(goal: goal)
                }
            }))
            self.present(inputView, animated: true)
        default:
            let alertView = UIAlertController(title: "Sorry", message: "This options is under Development", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alertView, animated: true)
        }
    }

}
