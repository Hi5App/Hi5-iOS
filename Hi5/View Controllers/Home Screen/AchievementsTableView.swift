//
//  AchievementsTableView.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/6/19.
//

import Foundation
import UIKit

extension UIImage {
    
    func resizeImageTo(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

struct achievement{
    let name:String
    let number:Int
    let reached:Bool
}

struct achievementSection{
    let sectionName:String
    let achievements:[achievement]
}

class AchievementsTableView:UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    var tableView:UITableView = UITableView(frame: CGRect(x: 100, y: 100, width: 300, height: 300), style: .insetGrouped)
    let achievementRecord:AchievementRecord
    var achievementsSections:[achievementSection] = []
    var performanceFeedback:performanceFeedback
    
    init(record:AchievementRecord,performance:performanceFeedback){
        self.achievementRecord = record
        self.performanceFeedback = performance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        
        setupTableView()
        setupDataSource()
    }
    
    func setupTableView(){
        self.view.addSubview(tableView)
        
        // constraits
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func setupDataSource(){
        // soma achievements
        let soma500 = achievement(name: "Mark 500 soma", number: 500, reached: achievementRecord.somaBronzeMedal)
        let soma1000 = achievement(name: "Mark 1000 soma", number: 1000, reached: achievementRecord.somaSliverMedal)
        let soma2000 = achievement(name: "Mark 2000 soma", number: 2000, reached: achievementRecord.somaGoldMedal)
        let somaSection = achievementSection(sectionName: "Soma in Hi5 iOS", achievements: [soma500,soma1000,soma2000])
        // check achievements
        let check500 = achievement(name: "Check 500 images", number: 500, reached: achievementRecord.checkBronzeMedal)
        let check1000 = achievement(name: "Check 1000 images", number: 1000, reached: achievementRecord.checkSlivereMedal)
        let check2000 = achievement(name: "Check 2000 images", number: 2000, reached: achievementRecord.checkGoldMedal)
        let checkSection = achievementSection(sectionName: "Check in Hi5 iOS", achievements: [check500,check1000,check2000])
        // total achievements
        let totalSoma = achievement(name: "Mark over 10000 soma", number: 10000, reached: performanceFeedback.totalsoma > 10000 ? true : false)
        let totalCheck = achievement(name: "Check over 10000 images", number: 10000, reached: performanceFeedback.totalCheck > 10000 ? true : false)
        let totalSection = achievementSection(sectionName: "Soma & Check in all devices", achievements: [totalSoma,totalCheck])
        achievementsSections.append(contentsOf: [somaSection,checkSection,totalSection])
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return achievementsSections[section].sectionName
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return achievementsSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return achievementsSections[section].achievements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let achievement = achievementsSections[indexPath.section].achievements[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = achievement.name
        var contentImage = UIImage()
        switch achievement.number{
        case 500:
            contentImage = UIImage(named: "bronze")!
        case 1000:
            contentImage = UIImage(named: "sliver")!
        case 2000:
            contentImage = UIImage(named: "gold")!
        default:
            contentImage = UIImage(named: "star")!
        }
        if let contentImage = contentImage.resizeImageTo(size: CGSize(width: 40, height: 32)){
            content.image = contentImage
        }
        cell.contentConfiguration = content
        if achievement.reached{
            cell.accessoryType = .checkmark
        }
        cell.selectionStyle = .none
        return cell
    }
    
}
