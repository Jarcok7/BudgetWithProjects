//
//  ReportsFilterTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 10/22/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class ReportsFilterTableViewController: UITableViewController {
    
    var accountRF: ReportFilter!
    var projectRF: ReportFilter!
    var categoryRF: ReportFilter!
    
    @IBOutlet weak var accountCell: UITableViewCell!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var accountSwitch: UISwitch!
    
    @IBOutlet weak var projectCell: UITableViewCell!
    @IBOutlet weak var projectLabel: UILabel!
    @IBOutlet weak var projectSwitch: UISwitch!
    
    @IBOutlet weak var category: UITableViewCell!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categorySwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        self.navigationItem.leftBarButtonItems = [cancelButton]
        
        let saveButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(saveTapped))
        self.navigationItem.rightBarButtonItems = [saveButton]
        
        self.navigationItem.title = "Filters"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureFilterCell(label: accountLabel, onOff: accountSwitch, rf: accountRF)
        configureFilterCell(label: projectLabel, onOff: projectSwitch, rf: projectRF)
        configureFilterCell(label: categoryLabel, onOff: categorySwitch, rf: categoryRF)
    }
    
    func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func saveTapped() {
        performSegue(withIdentifier: "unwindToReportsFromFilter", sender: nil)
    }

    @IBAction func accountSwitchChanged(_ sender: UISwitch) {
        accountRF.use = sender.isOn
    }
    
    @IBAction func projectSwitchChanged(_ sender: UISwitch) {
        projectRF.use = sender.isOn
    }
    
    @IBAction func categorySwitchChanged(_ sender: UISwitch) {
        categoryRF.use = sender.isOn
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "fromAccountToFilter" {
            let controller = segue.destination as! SelectFilterItemsTableViewController
            controller.itemsType = "Account"
            controller.reportFilter = accountRF
        } else if segue.identifier == "fromProjectToFilter" {
            let controller = segue.destination as! SelectFilterItemsTableViewController
            controller.itemsType = "Project"
            controller.reportFilter = projectRF
        }else if segue.identifier == "fromCategoryToFilter" {
            let controller = segue.destination as! SelectFilterItemsTableViewController
            controller.itemsType = "Category"
            controller.reportFilter = categoryRF
        }
        
    }
    
    // MARK: - Helpers
    func configureFilterCell(label: UILabel, onOff: UISwitch, rf: ReportFilter) {
        let desc = rf.description
        if desc == "" {
            label.text = "empty \(rf.attributeName) filter"
            label.textColor = UIColor.lightGray
        } else {
            label.text = desc
            label.textColor = UIColor.darkText
        }
        onOff.isOn = rf.use
    }

}
