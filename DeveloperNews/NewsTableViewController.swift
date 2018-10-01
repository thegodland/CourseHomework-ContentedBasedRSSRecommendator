//
//  NewsTableViewController.swift
//  DeveloperNews
//
//  Created by Duc Tran on 9/14/17, amended by Xiang Liu on 30 Sep, 2018
//  Copyright © 2017 Duc Tran. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController
{
    
    var passedRankedItems : [RankedItem]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let items = passedRankedItems{
            passedRankedItems = items.sorted(by: { $0.similarity > $1.similarity })
        }

        tableView.estimatedRowHeight = 155.0
        tableView.rowHeight = UITableView.automaticDimension
        
        OperationQueue.main.addOperation {
            self.tableView.reloadSections(IndexSet(integer: 0), with: .left)
        }
        
        
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let rssItems = passedRankedItems else {
            return 0
        }
        
        // rssItems
        return rssItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NewsTableViewCell
        if let item = passedRankedItems?[indexPath.item] {
            cell.item = item
            cell.selectionStyle = .none
            
        }
        
        return cell
    }
    
}


















