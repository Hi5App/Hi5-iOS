//
//  AchievementsView.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/6/14.
//

import UIKit

extension UIColor{
    static let lightGold = UIColor(red: 255/255, green: 209/255, blue: 59/255, alpha: 1)
    static let bronze = UIColor(red: 197/255, green: 137/255, blue: 102/255, alpha: 1)
    static let sliver = UIColor(red: 189/255, green: 196/255, blue: 207/255, alpha: 1)
    static let gold = UIColor(red: 255/255, green: 188/255, blue: 61/255, alpha: 1)
}

enum AchievementType:String{
    case dailySomaGoal = "soma"
    case dailyCheckGoal = "check"
    case total500Soma = "mark total 500 somas"
    case total1000Soma = "mark total 1000 somas"
    case total2000Soma = "mark total 2000 somas"
    case total500Check = "check total 500 images"
    case total1000Check = "check total 1000 images"
    case total2000Check = "check total 2000 images"
}

struct achievementsDescriptions{
    let imageName:String
    let medalTitle:String
    let medalTitleColor:UIColor
    let detailText:String
}

extension UIView {
    func addLayerGradient(colors:[CGColor]) {
        let layer : CAGradientLayer = CAGradientLayer()
        layer.frame = self.bounds
        layer.cornerRadius = CGFloat(20)
        layer.colors = colors
        layer.startPoint = CGPoint(x: 0.2,y: 0.0)
        layer.endPoint = CGPoint(x: 0.8,y: 1.0)
        layer.locations = [0.0,0.4,1.0]
        self.layer.insertSublayer(layer, at: 0)
    }
}

class ActualGradientButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.frame = self.bounds
        l.colors = [UIColor.systemYellow.cgColor, UIColor.systemPink.cgColor]
        l.startPoint = CGPoint(x: 0, y: 0.5)
        l.endPoint = CGPoint(x: 1, y: 0.5)
        l.cornerRadius = 16
        layer.insertSublayer(l, at: 0)
        return l
    }()
}

extension UIViewController{
    func drawAchievementsView(for type:AchievementType,with goal:Int){
        
        // construct configuration
        let rawValue  = type.rawValue
        let currentConfig:achievementsDescriptions!
        switch type {
        case .dailySomaGoal,.dailyCheckGoal:
            currentConfig = achievementsDescriptions(imageName: "Trophy", medalTitle: "\(goal)/\(goal)", medalTitleColor: .lightGold, detailText: "You have reached your\n daily \(rawValue) goal")
        case .total500Soma,.total500Check:
            currentConfig = achievementsDescriptions(imageName: "bronze", medalTitle: "Bronze Medal", medalTitleColor: .bronze, detailText: "You have used Hi5 iOS to\n \(rawValue)")
        case .total1000Soma,.total1000Check:
            currentConfig = achievementsDescriptions(imageName: "sliver", medalTitle: "Sliver Medal", medalTitleColor: .sliver, detailText: "You have used Hi5 iOS to\n \(rawValue)")
        case .total2000Soma,.total2000Check:
            currentConfig = achievementsDescriptions(imageName: "gold", medalTitle: "Gold Medal", medalTitleColor: .gold, detailText: "You have used Hi5 iOS to\n \(rawValue)")
        }
        guard currentConfig != nil else {return}
        // use configuration
        let backView = UIView(frame: CGRect(x: 0, y: 0, width: 264, height: 364))
        let colorArray = [CGColor(red: 64/255, green: 82/255, blue: 241/255, alpha: 1),
                          CGColor(red: 115/255, green: 120/255, blue: 241/255, alpha: 1),
                        CGColor(red: 18/255, green: 22/255, blue: 109/255, alpha: 1)]
        backView.addLayerGradient(colors: colorArray)
        
        var constraints:[NSLayoutConstraint] = []
        // medal image view
        let medalImage = UIImageView(frame: CGRect(x: backView.bounds.width/2-120/2, y: backView.bounds.height/2 - 150, width: 120, height: 87))
        medalImage.image = UIImage(named: currentConfig.imageName)
        medalImage.contentMode = .scaleAspectFit
        
        // medal title view
        let medalTitle = UILabel()
        medalTitle.text = currentConfig.medalTitle
        let medalTitleFont = UIFont.systemFont(ofSize: 24, weight: .heavy)
        medalTitle.font = medalTitleFont
        medalTitle.textColor = currentConfig.medalTitleColor
        
        let medalTitleCenter = medalTitle.centerXAnchor.constraint(equalTo: backView.centerXAnchor)
        let medalTitleTop = medalTitle.bottomAnchor.constraint(equalTo: backView.topAnchor,constant: 160)
        medalTitle.translatesAutoresizingMaskIntoConstraints = false
        
        constraints.append(medalTitleCenter)
        constraints.append(medalTitleTop)
        
        
        // congrats view
        let congratsTitle = UILabel()
        congratsTitle.text = "Congratulations!"
        let titleFont = UIFont.systemFont(ofSize: 26, weight: .heavy)
        congratsTitle.font = titleFont
        congratsTitle.textColor = .white
        congratsTitle.textAlignment = .center
        
        let conCenter = congratsTitle.centerXAnchor.constraint(equalTo: backView.centerXAnchor)
        let conBottom = congratsTitle.bottomAnchor.constraint(equalTo: backView.bottomAnchor,constant: -110)
        congratsTitle.translatesAutoresizingMaskIntoConstraints = false
        
        constraints.append(conCenter)
        constraints.append(conBottom)
        // detal text view
        let detailText = UILabel()
        detailText.numberOfLines = 2
        detailText.textAlignment = .center
        detailText.text = currentConfig.detailText
        let textFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        detailText.font = textFont
        detailText.textColor = .white
        
        let detailCenter = detailText.centerXAnchor.constraint(equalTo: backView.centerXAnchor)
        let detailBottom = detailText.bottomAnchor.constraint(equalTo: backView.bottomAnchor,constant: -65)
        detailText.translatesAutoresizingMaskIntoConstraints = false
        
        constraints.append(detailCenter)
        constraints.append(detailBottom)
        
        // acknowledge button
        
        
        backView.addSubview(medalImage)
        backView.addSubview(medalTitle)
        backView.addSubview(congratsTitle)
        backView.addSubview(detailText)
        NSLayoutConstraint.activate(constraints)
        self.view.addSubview(backView)
    }
}
