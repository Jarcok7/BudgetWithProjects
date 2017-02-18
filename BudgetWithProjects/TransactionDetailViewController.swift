//
//  DetailViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 5/30/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class TransactionDetailViewController: UITableViewController {

    @IBOutlet weak var dateCell: UITableViewCell!
    @IBOutlet weak var accountSumCell: UITableViewCell!
    @IBOutlet weak var correspondAccountSumCell: UITableViewCell!
    @IBOutlet weak var projectCell: UITableViewCell!
    @IBOutlet weak var categoryCell: UITableViewCell!
    @IBOutlet weak var descCell: UITableViewCell!
    @IBOutlet weak var repaymentDateCell: UITableViewCell!
    @IBOutlet weak var transactCell: UITableViewCell!
    

    var detailItem: TempTransaction?
    var transaction: Transaction?
    var planTransaction = false

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
            if detail.plan {
                self.navigationItem.title = "Plan transaction"
                planTransaction = true
            } else {
                self.navigationItem.title = "Transaction"
            }
            
            configureDate()
            configureRepaymentDate()
            
            accountSumCell.textLabel?.text = detail.account?.name
            let sumFormatter = NumberFormatter()
            sumFormatter.numberStyle = .currencyISOCode
            sumFormatter.currencyCode = detail.usedCurrency?.code
            accountSumCell.detailTextLabel?.text = sumFormatter.string(from: NSNumber(value: detail.sum))
            accountSumCell.detailTextLabel?.textColor = (detail.sum > 0 ? SumViewController.plusColor() : SumViewController.minusColor())
            
            if let project = detail.project {
                projectCell.textLabel?.text = project.shortName
                projectCell.detailTextLabel?.text = project.name
                projectCell.textLabel?.textColor = UIColor.darkText
            } else {
                projectCell.textLabel?.text = "project"
                projectCell.detailTextLabel?.text = ""
                projectCell.textLabel?.textColor = UIColor.lightGray
            }
            
            categoryCell.textLabel?.text = detail.category?.name
            
            if detail.desc.isEmpty {
                descCell.textLabel?.text = "description"
                descCell.textLabel?.textColor = UIColor.lightGray
            } else {
                descCell.textLabel?.text = detail.desc
                descCell.textLabel?.textColor = UIColor.darkText
            }
            
            let categoryType = detail.category?.type
            if categoryType == CategoryType.transfer || categoryType == CategoryType.exchange {
                correspondAccountSumCell.textLabel?.text = detail.correspondingAccount?.name
                sumFormatter.currencyCode = detail.correspondingUsedCurrency?.code
                correspondAccountSumCell.detailTextLabel?.text = sumFormatter.string(from: NSNumber(value: detail.correspondingSum))
                correspondAccountSumCell.detailTextLabel?.textColor = (detail.correspondingSum > 0 ? SumViewController.plusColor() : SumViewController.minusColor())
            }
        }
        
    }
    
    func configureDate() {
        
        if let timeStamp = detailItem?.timeStamp {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .none
            let strDate = dateFormatter.string(from: timeStamp as Date)
            
            dateCell.textLabel?.text = strDate
            dateCell.textLabel?.textColor = UIColor.darkText
        } else {
            dateCell.textLabel?.text = "without date"
            dateCell.textLabel?.textColor = UIColor.lightGray
        }
    }
    
    func configureRepaymentDate() {
        
        if let repaymentDate = detailItem?.repaymentDate {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .none
            let strDate = dateFormatter.string(from: repaymentDate as Date)
            
            repaymentDateCell.textLabel?.text = "repayment " + strDate
            repaymentDateCell.textLabel?.textColor = UIColor.darkText
        } else {
            repaymentDateCell.textLabel?.text = "without repayment date"
            repaymentDateCell.textLabel?.textColor = UIColor.lightGray
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func transactTapped(_ sender: UIButton) {
        if let detailItem = detailItem {
            if let transaction = self.transaction {
                detailItem.plan = false
                detailItem.timeStamp = Date()
                detailItem.fillTransaction(transaction)
                
                if let corrTr = transaction.correspondingTransaction {
                    if corrTr.plan {
                        corrTr.plan = false
                        corrTr.timeStamp = detailItem.timeStamp
                    }
                }
                
                self.performSegue(withIdentifier: "unwindToTransactionList", sender: self)
            }
        }
    }
    
    func save() {
        if let detailItem = detailItem {
            if let context = managedObjectContext {
                
                let isNew = detailItem.id.isEmpty
                
                if isNew {
                    detailItem.id = UUID().uuidString
                }
                
                let categoryType = detailItem.category?.type
                if categoryType == CategoryType.transfer || categoryType == CategoryType.exchange {
                    var corrTransaction: Transaction?
                    
                    if isNew {
                        corrTransaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context) as? Transaction
                    } else {
                        corrTransaction = detailItem.correspondingTransaction
                    }
                    
                    if let corrTransaction = corrTransaction {
                        
                        corrTransaction.id = detailItem.id
                        corrTransaction.category = detailItem.category
                        corrTransaction.desc = detailItem.desc
                        corrTransaction.project = detailItem.project
                        corrTransaction.timeStamp = detailItem.timeStamp
                        
                        corrTransaction.account = detailItem.correspondingAccount
                        
                        if categoryType == CategoryType.exchange {
                            corrTransaction.sum = detailItem.correspondingSum
                            corrTransaction.usedCurrency = detailItem.correspondingUsedCurrency
                        } else {
                            corrTransaction.sum = -detailItem.sum
                            corrTransaction.usedCurrency = detailItem.usedCurrency
                        }
                        corrTransaction.plan = detailItem.plan
                        corrTransaction.planWithoutDate = (corrTransaction.timeStamp == nil) && corrTransaction.plan
                        corrTransaction.subsidiary = true
                        
                        detailItem.correspondingTransaction = corrTransaction
                    }
                    
                }
                
                if categoryType == CategoryType.loan && isNew {
                    
                    if let repaymentCategory = Category.getRepaymentCategory(managedObjectContext!) {
                        let repaymentTransaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context) as! Transaction
                        repaymentTransaction.id = UUID().uuidString
                        repaymentTransaction.category = repaymentCategory
                        repaymentTransaction.desc = detailItem.desc
                        repaymentTransaction.project = detailItem.project
                        repaymentTransaction.timeStamp = detailItem.repaymentDate
                        
                        repaymentTransaction.account = detailItem.account
                        
                        repaymentTransaction.sum = -detailItem.sum
                        repaymentTransaction.usedCurrency = detailItem.usedCurrency
                        
                        repaymentTransaction.plan = true
                        repaymentTransaction.planWithoutDate = (repaymentTransaction.timeStamp == nil)
                    }
                    
                }
                
                if self.transaction == nil {
                    self.transaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context) as? Transaction

                }
                
                if let transaction = self.transaction {
                    detailItem.fillTransaction(transaction)
                    self.performSegue(withIdentifier: detailItem.initiateFromMain ? "unwindToMain" : "unwindToTransactionList", sender: self)
                }
            }
        }
    }
    
    func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        let serviceCategory: [CategoryType] = [CategoryType.transfer, CategoryType.exchange]
        
        if cell == correspondAccountSumCell && !serviceCategory.contains((self.detailItem?.category?.type)!) {
            
            return 0
        }
        
        if cell == categoryCell && serviceCategory.contains((self.detailItem?.category?.type)!){
            
            return 0
        }
        
        if cell == repaymentDateCell && (self.detailItem?.category?.type != CategoryType.loan || !(detailItem?.id.isEmpty)!) {
            
            return 0
        }
        
        if (cell == transactCell && !planTransaction) || (cell == transactCell && planTransaction && transaction == nil) {
            return 0
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if cell == correspondAccountSumCell {
            if detailItem?.category?.type == CategoryType.transfer {
                self.performSegue(withIdentifier: "fromDetailToCorrAccount", sender: self)
            } else if detailItem?.category?.type == CategoryType.exchange {
                self.performSegue(withIdentifier: "fromDetailToCorrSum", sender: self)
            }
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromDetailToDatePicker" {
            let controller = segue.destination as! DatePickerViewController
            controller.timeStamp = detailItem?.timeStamp
            controller.detailItem = detailItem
        } else if segue.identifier == "fromDetailToRemaymentDatePicker" {
            let controller = segue.destination as! DatePickerViewController
            controller.timeStamp = detailItem?.repaymentDate
            controller.detailItem = detailItem
            controller.repaymentMode = true
        } else if segue.identifier == "fromDetailToSum" {
            let controller = segue.destination as! SumViewController
            controller.detailItem = detailItem
            controller.managedObjectContext = managedObjectContext
        } else if segue.identifier == "fromDetailToProjects" {
            let controller = segue.destination as! ProjectsTableViewController
            controller.detailItem = detailItem
        } else if segue.identifier == "fromDetailToCategories" {
            let controller = segue.destination as! CategoryTableViewController
            controller.detailItem = detailItem
            controller.editDetailMode = true
        } else if segue.identifier == "fromDetailToDescription" {
            let controller = segue.destination as! DescriptionTableViewController
            controller.detailItem = detailItem
            controller.editDetailMode = true
        } else if segue.identifier == "fromDetailToCorrAccount" {
            let controller = segue.destination as! AccountsTableViewController
            controller.detailItem = detailItem
            controller.editDetailMode = true
        } else if segue.identifier == "fromDetailToCorrSum" {
            let controller = segue.destination as! SumViewController
            controller.detailItem = detailItem
            controller.exchangeCurrencyMode = true
            controller.managedObjectContext = managedObjectContext
        }
        
    }
    
    @IBAction func unwindToDetailsFromDatePicker(_ sender: UIStoryboardSegue) {
        let controller = sender.source as! DatePickerViewController
        
        if controller.repaymentMode {
            configureRepaymentDate()
        } else {
            configureDate()
        }
    }
    
    @IBAction func unwindToDetailsFromSum(_ sender: UIStoryboardSegue) {
        configureView()
    }
    
    @IBAction func unwindToDetailsFromProjects(_ sender: UIStoryboardSegue) {
        configureView()
    }
    
    @IBAction func unwindToDetailsFromCategories(_ sender: UIStoryboardSegue) {
        configureView()
    }
    
    @IBAction func unwindToDetailsFromDescription(_ sender: UIStoryboardSegue) {
        configureView()
    }
    
    @IBAction func unwindToDetailsFromAccounts(_ sender: UIStoryboardSegue) {
        configureView()
    }

    // MARK: - MOC
    var managedObjectContext: NSManagedObjectContext? {
        
        //        if let detailItem = detailItem {
        //            return detailItem.managedObjectContext!
        //        }
        
        if _managedObjectContext != nil {
            return _managedObjectContext!
        }
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if let moc = delegate?.managedObjectContext {
            _managedObjectContext = moc
            return _managedObjectContext!
        }
        
        return nil
    }
    
    var _managedObjectContext: NSManagedObjectContext? = nil
}

