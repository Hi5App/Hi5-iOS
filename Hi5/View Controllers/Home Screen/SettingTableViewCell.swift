//
//  SettingTableViewCell.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/4.
//

import UIKit

protocol AutoSignInDelegate{
    func didFlipSwitch(value:Bool,row:Int)
}

class SettingTableViewCell: UITableViewCell {
    static let identifier = "SettingTableViewCell"
    
    var autoDelegate:AutoSignInDelegate?
    var row:Int!
    
    private let switchView:UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = UIColor.systemOrange
        switchView.isOn = false
        return switchView
    }()
    
    private let labelView:UILabel = {
        let labelView = UILabel()
        labelView.text = "test"
        return labelView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(switchView)
        switchView.addTarget(self, action: #selector(flipAutoSignInSwitch), for: .valueChanged)
        contentView.addSubview(labelView)
    }
    
    @objc func flipAutoSignInSwitch(myswitch:UISwitch){
        autoDelegate?.didFlipSwitch(value: myswitch.isOn, row: self.row)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switchView.frame = CGRect(x: contentView.frame.size.width-5-55, y: 7, width: 50, height: contentView.frame.size.height-10)
        labelView.frame = CGRect(x: 5, y: 5, width: 200, height: contentView.frame.size.height-10)
    }
    
    func configure(with option:settingOptions){
        labelView.text = "   " + option.title
        switchView.isOn = option.isOn
    }
    
}
