//
//  CurrencyTableViewCell.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 6/22/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class CurrencyTableViewCell: UITableViewCell {

    @IBOutlet weak var code: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var used: UISwitch!
    
    weak var delegate: CurrenciesTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func usedChanged(_ sender: UISwitch) {
        self.delegate?.didChangeSwitchState(self, isOn: sender.isOn)
    }
    
    
}

protocol CurrenciesTableViewCellDelegate : class {
    func didChangeSwitchState(_ sender: CurrencyTableViewCell, isOn: Bool)
}
