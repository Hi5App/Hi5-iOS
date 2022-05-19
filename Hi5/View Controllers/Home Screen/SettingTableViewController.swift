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

struct normalOptions{
    var title:String
}

class SettingTableViewController: UITableViewController,passUserPrefChange,AutoSignInDelegate{
    
    var textSettings:[normalOptions] = []
    var Settings:[settingOptions] = []
    var userPref:UserPreferences!
    var delegate:passUserPrefChange!
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate.userPref = self.userPref
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.identifier)
        tableView.register(UITableViewCell.self , forCellReuseIdentifier: "uitableviewcell")
        configureModel()
        self.title = "Setting"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return Settings.count
        case 1:
            return textSettings.count
        default:
            fatalError("exceed section number")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section{
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.identifier, for: indexPath) as! SettingTableViewCell
            cell.autoDelegate = self
            cell.row = indexPath.row
            cell.configure(with: Settings[indexPath.row])
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "uitableviewcell")!
            cell.textLabel?.text = textSettings[0].title
            return cell
        default:
            fatalError("exceed section number")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1{
            switch indexPath.row{
            case 0:
                clearCache()
            default:
                fatalError("unknown index")
            }
        }
    }
    
    func clearCache(){
        let cacheSize = CacheCleanHelper.getCacheSize()
        if CacheCleanHelper.deleteCacheFile(){
            let alert = UIAlertController(title: "Cache Cleaned", message: "Total \(String(format: "%.1fM", cacheSize)) was removed", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel,handler: { (action) in
                self.textSettings[0].title = "Clear Cache"
                self.tableView.reloadData()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func configureModel(){
        Settings.append(contentsOf: [
            settingOptions(icon: nil, title: "Auto Sign In", isOn: userPref.autoLogin),
            settingOptions(icon: nil, title: "Image Sharpening", isOn: userPref.ImageShapening)
        ])
        let cacheSize = CacheCleanHelper.getCacheSize()
        if cacheSize >= 10.0{
            textSettings.append(normalOptions(title: "Clear Cache (\(String(format: "%.1fM", cacheSize)))"))
        }else{
            textSettings.append(normalOptions(title: "Clear Cache"))
        }
        
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
