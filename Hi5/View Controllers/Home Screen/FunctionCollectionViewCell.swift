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
    
    
    func setup(with function:softwareFunction){
        functionName.text = function.name
        functionImage.image = function.image
    }
}
