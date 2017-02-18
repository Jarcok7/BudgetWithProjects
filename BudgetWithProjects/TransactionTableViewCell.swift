//
//  TransactionTableViewCell.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 9/15/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {

    @IBOutlet weak var shortDesc: UILabel!
    @IBOutlet weak var longDesc: UILabel!
    @IBOutlet weak var sum: UILabel!
    @IBOutlet weak var account: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
