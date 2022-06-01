//
//  FormerResultsController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/6/1.
//

import UIKit

class FormerResultsController: UITableViewController {
    
    let results:QueryArborFormerResults
    
    init(results:QueryArborFormerResults){
        self.results = results
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.style = .insetGrouped
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return results.formerResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell = UITableViewCell.init(style: .value1, reuseIdentifier: "cell")
        var config = cell.defaultContentConfiguration()
        config.text = convertTypes(number: results.formerResults[indexPath.row].Result) 
        config.secondaryText = results.formerResults[indexPath.row].Owner
        cell.contentConfiguration = config
        return cell
    }
    
    func convertTypes(number:Int)->String{
        switch number{
        case -1:
            return "Bad Image"
        case 4:
            return "Good"
        case 3:
            return "SWC Bad"
        case 2:
            return "Normal"
        default:
            return "unknown image type"
        }
   
    }

}
