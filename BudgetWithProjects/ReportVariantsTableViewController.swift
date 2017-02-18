//
//  ReportVariantsTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 12/8/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class ReportVariantsTableViewController: UITableViewController {
    
    var reportVariants: [ReportVariant] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.navigationItem.title = "Report variants"

        reportVariants = ReportVariant.loadVariants()
        fillVariants()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let currentIndex = reportVariants.index(where: { $0.current }) {
            let indexPath = IndexPath(row: currentIndex, section: 0)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return reportVariants.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reportVariantCell", for: indexPath)

        let variant = reportVariants[indexPath.row]
        
        cell.textLabel?.text = variant.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        for index in 0..<reportVariants.endIndex {
            reportVariants[index].current = false
        }
        
        reportVariants[indexPath.row].current = true
        
        ReportVariant.save(reportVariants)
        
        performSegue(withIdentifier: "unwindToReportsFromVariants", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let variant = reportVariants[indexPath.row]
        
        let edit = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            // Rename variant
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Rename variant", message: nil, preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (textField) -> Void in
                textField.text = variant.name
                textField.placeholder = "Variant name"
                textField.autocapitalizationType = .sentences
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                let textField = alert.textFields![0] as UITextField
                let variantName = textField.text!
                
                if variantName == "" {
                    return
                }
                
                variant.name = variantName
                                
                self.tableView.reloadRows(at: [index], with: .automatic)
                
                ReportVariant.save(self.reportVariants)
                
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        
        let delete = UITableViewRowAction(style: .default, title: "Delete") { action, index in
            self.reportVariants.remove(at: index.row)
            
            self.tableView.deleteRows(at: [index], with: .automatic)
            
            ReportVariant.save(self.reportVariants)
        }
        
        if reportVariants[indexPath.row].current {
            return [edit]
        }
        
        return [delete, edit]
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return !reportVariants[indexPath.row].predestinated
    }

    // MARK - Helpers
    
    func fillVariants() {
        if !reportVariants.contains(where: {$0.name == "Balance"} ) {
            let newRV = ReportVariant(type: .balance, name: "Balance")
            newRV.predestinated = true
            newRV.standartPeriod = StandartPeriod.thisMonth
            newRV.current = (reportVariants.count == 0)
            
            reportVariants.append(newRV)
        }
    }

}
