//
//  FunctionCollectionViewCell.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/3/22.
//

import UIKit

class functionCollectionViewCell:UICollectionViewCell{
    @IBOutlet var functionName: UILabel!
    @IBOutlet var functionImage: UIImageView!
    
    func beautifyCell(){
        self.backgroundColor = UIColor.systemCyan
        // add connerRadius
        self.contentView.layer.cornerRadius = 2.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true
        // add shadow
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 1.0
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath
    }
    
    func setup(with function:softwareFunction){
        functionName.text = function.name
        functionImage.image = function.image
    }
}
