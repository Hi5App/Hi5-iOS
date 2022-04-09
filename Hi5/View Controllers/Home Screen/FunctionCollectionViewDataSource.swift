//
//  functionCollectionViewDataSource.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/3/19.
//

import UIKit

struct softwareFunction{
    let name:String
    let decription:String
    let image:UIImage?
}



class functionCollectionViewDataSource:NSObject,UICollectionViewDataSource{
    
    let softwareFunctions: [softwareFunction] = [
        softwareFunction(name: "Marker Factory", decription: "produce soma data", image: UIImage(systemName: "pencil.circle")),
        softwareFunction(name: "Annotation", decription: "Annotate images",image: UIImage(systemName: "pencil.tip")),
        softwareFunction(name: "Check",decription: "Examine soma data", image: UIImage(systemName: "checkmark.square")),
        softwareFunction(name: "Smart Imageing",decription: "no description", image: UIImage(systemName: "brain.head.profile")),
        softwareFunction(name: "Chat",decription: "Chat with friends", image: UIImage(systemName: "message")),
        softwareFunction(name: "Help",decription: "read the mannal", image: UIImage(systemName: "questionmark.circle"))
    ]
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return softwareFunctions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "functionCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! functionCollectionViewCell
        cell.contentView.backgroundColor = UIColor(named: "cellBackground")
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 2.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.setup(with: softwareFunctions[indexPath.row])
        return cell
    }
    
    
}
