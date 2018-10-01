//
//  NewsTableViewCell.swift
//  DeveloperNews
//
//  Created by Duc Tran on 9/14/17, amended by Xiang Liu on 30 Sep, 2018
//  Copyright © 2017 Duc Tran. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var descriptionLabel:UILabel!
    @IBOutlet weak var dateLabel:UILabel!
    

    var item: RankedItem! {
        didSet {
            titleLabel.text = item.title
            descriptionLabel.text = String(item.similarity)
            dateLabel.text = item.pubDate
        }
    }
}












