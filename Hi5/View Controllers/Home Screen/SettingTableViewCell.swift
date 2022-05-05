//
//  SettingTableViewCell.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/4.
//

import UIKit

class SettingTableViewCell: UITableViewCell {
    static let identifier = "SettingTableViewCell"
    
    private let switchView:UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = .blue
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
        contentView.addSubview(labelView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switchView.frame = CGRect(x: contentView.frame.size.height-5-100, y: 5, width: 100, height: contentView.frame.size.height-10)
        labelView.frame = CGRect(x: 5, y: 5, width: 200, height: contentView.frame.size.height-10)
    }
    
}
