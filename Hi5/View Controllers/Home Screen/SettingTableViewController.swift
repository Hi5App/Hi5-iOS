//
//  SettingTableViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/4.
//

import UIKit

struct settingOptions{
    let icon:UIImage?
    let title:String
    let isOn:Bool
}

class SettingTableViewController: UITableViewController,passUserPrefChange,AutoSignInDelegate{
    
    var Settings:[settingOptions] = []
    var userPref:UserPreferences!
    var delegate:passUserPrefChange!
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate.userPref = self.userPref
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.identifier)
        configureModel()
        self.title = "Setting"
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.identifier, for: indexPath) as! SettingTableViewCell
        cell.autoDelegate = self
        cell.row = indexPath.row
        cell.configure(with: Settings[indexPath.row])
        return cell
    }
    
    func configureModel(){
        Settings.append(contentsOf: [
            settingOptions(icon: nil, title: "Auto Sign In", isOn: userPref.autoLogin),
            settingOptions(icon: nil, title: "Image Sharpening", isOn: userPref.ImageShapening)
        ])
    }
    
    func didFlipSwitch(value:Bool,row:Int) {
        switch row{
        case 0:
            userPref.autoLogin = value
        case 1:
            userPref.ImageShapening = value
        default:
            print("unknow setting option")
        }
        
    }
}
