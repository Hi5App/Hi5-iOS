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

class SettingTableViewController: UITableViewController {

    var Settings:[settingOptions]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.identifier)
        configureModel()
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return Settings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.identifier, for: indexPath)
        return cell
    }
    
    func configureModel(){
        Settings.append(contentsOf: [
            settingOptions(icon: nil, title: "Auto Sign In", isOn: false),
            settingOptions(icon: nil, title: "Image Sharpening", isOn: false)
        ])
    }

}
