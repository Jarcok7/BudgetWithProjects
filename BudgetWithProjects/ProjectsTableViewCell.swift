//
//  ProjectsTableViewCell.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/30/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class ProjectsTableViewCell: UITableViewCell {

    @IBOutlet weak var shortName: UILabel!
    @IBOutlet weak var longName: UILabel!
    @IBOutlet weak var openSwitch: UISwitch!
    
    weak var delegate: ProjectTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func openChanged(_ sender: UISwitch) {
        self.delegate?.didChangeSwitchState(self, isOn: sender.isOn)
    }
    
}

protocol ProjectTableViewCellDelegate : class {
    func didChangeSwitchState(_ sender: ProjectsTableViewCell, isOn: Bool)
}
