//
//  UserInfoViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/16.
//

import UIKit

class UserInfoViewController: UITableViewController{
    
    var loginUser:User!{
        didSet{
            details = [[loginUser.userName,loginUser.email],[loginUser.nickName,loginUser.inviterCode!,String(loginUser.score ?? 0)]]
        }
    }
    let sectionNames = ["Basic Info","Detail"]
    let titles = [["Username","Email"],["Nickname","InviterCode","Score"]]
    let imageNames = [["person.fill","mail.fill"],["heart.fill","globe.europe.africa.fill","graduationcap.fill"]]
    var details:[[String]]!
   
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tintColor = UIColor.systemOrange
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionNames.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return titles[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: imageNames[indexPath.section][indexPath.row])
        content.text = details[indexPath.section][indexPath.row]
        content.secondaryText = titles[indexPath.section][indexPath.row]
        cell.contentConfiguration = content
        return cell
    }

}
