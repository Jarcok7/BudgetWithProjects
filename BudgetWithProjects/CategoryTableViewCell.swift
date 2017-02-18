//
//  CategoryTableViewCell.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 11/22/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLable: UILabel!
    @IBOutlet weak var addDescButton: UIButton!
    
    weak var delegate: CategoryTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func AddDescTapped(_ sender: UIButton) {
        self.delegate?.addDescTapped(self)
    }

}

protocol CategoryTableViewCellDelegate : class {
    func addDescTapped(_ sender: CategoryTableViewCell)
}
