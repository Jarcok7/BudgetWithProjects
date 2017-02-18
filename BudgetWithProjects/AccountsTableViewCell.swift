//
//  AccountsTableViewCell.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 12/4/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class AccountsTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    weak var delegate: AccountsTableViewCellDelegate?
    @IBOutlet weak var openSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func openSwitchChanged(_ sender: UISwitch) {
        self.delegate?.didChangeSwitchState(self, isOn: openSwitch.isOn)
    }
}

protocol AccountsTableViewCellDelegate : class {
    func didChangeSwitchState(_ sender: AccountsTableViewCell, isOn: Bool)
}
