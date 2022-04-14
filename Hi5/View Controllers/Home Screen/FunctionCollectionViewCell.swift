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
    
    override var isHighlighted: Bool {
        didSet {
          shrink(down: isHighlighted)
        }
      }
    
    func setup(with function:softwareFunction){
        functionName.text = function.name
        functionImage.image = function.image
    }
    
    func shrink(down: Bool) {
      UIView.animate(withDuration: 0.2) {
        if down {
          self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }else{
          self.transform = .identity
        }
      }
    }
}
