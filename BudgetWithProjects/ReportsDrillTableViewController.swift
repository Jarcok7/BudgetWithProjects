//
//  ReportsDrillTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 11/26/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class ReportsDrillTableViewController: UITableViewController {
    
    var items: [[String:AnyObject]] = []
    var groupBy = ""
    var presentCurrency: UsedCurrency?
    var predicate: NSPredicate!
    var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(cancelTapped))
    }

    override func viewWillAppear(_ animated: Bool) {
        let itemsWithRates = Transaction.fetchReportInfoWithRates(managedObjectContext: managedObjectContext, groupBy: groupBy, predicate: predicate)
        
        items = Transaction.getReportInfo(managedObjectContext: managedObjectContext!, itemsWithRates: itemsWithRates, presentCurrency: presentCurrency!, needSorting: true, insertZeroTotals: false)
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        if let groupName = item["groupName"] as? String {
            let cell = tableView.dequeueReusableCell(withIdentifier: groupName == "Balance" ? "TotalCell" : "GroupCell", for: indexPath)
            cell.textLabel?.text = groupName
            
            let sumTotal = item["sumTotal"] as? Double ?? 0
            cell.detailTextLabel?.text = Transaction.getSumPresentation(sumTotal, currencyCode: presentCurrency?.code)
            
            if sumTotal > 0 {
                cell.detailTextLabel?.textColor = SumViewController.plusColor()
            } else if sumTotal < 0 {
                cell.detailTextLabel?.textColor = SumViewController.minusColor()
            }
            
            if indexPath.row != 0 {
                addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.black)
            }
            
            if indexPath.row == items.count - 1 {
                addFooterSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.black)
            }
            
            return cell
            
        } else if let desc = item["item"] as? String {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            cell.textLabel?.text = (desc == "" ? "<without desc.>" : desc)
            
            let sumTotal = item["sumTotal"] as? Double ?? 0
            cell.detailTextLabel?.text = Transaction.getSumPresentation(sumTotal, currencyCode: presentCurrency?.code)
            
            if sumTotal > 0 {
                cell.detailTextLabel?.textColor = SumViewController.plusColor()
            } else if sumTotal < 0 {
                cell.detailTextLabel?.textColor = SumViewController.minusColor()
            }
            
            addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.lightGray)
            
            cell.subviews.filter({$0.tag == 42}).first?.removeFromSuperview()
            
            if indexPath.row == items.count - 1 {
                addFooterSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.black)
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let item = items[indexPath.row]
        
        if let _ = item["groupName"] {
            return 40
        }
        
        return 35
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let item = items[indexPath.row]
        
        if let _ = item["groupName"] {
            return
        }
        
        if let _item = item["item"] as? String {
            let transactionsVC = self.storyboard!.instantiateViewController(withIdentifier: "TransactionsVC") as! MasterViewController
            transactionsVC.drillmode = true
            
            let selectedRowPredicate = NSPredicate(format: "\(groupBy) == %@", _item)
            
            transactionsVC.drillPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, selectedRowPredicate])
            
            self.navigationController!.pushViewController(transactionsVC, animated: true)
        }
    }

    // MARK - Helpers
    func addHeaderSeparator(cell: UITableViewCell, separatorThickness: CGFloat, separatorBackgroundColor: UIColor) {
        
        let additionalSeparator = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: cell.frame.size.width, height: separatorThickness)))
        
        additionalSeparator.backgroundColor = separatorBackgroundColor
        cell.addSubview(additionalSeparator)
    }
    
    func addFooterSeparator(cell: UITableViewCell, separatorThickness: CGFloat, separatorBackgroundColor: UIColor) {
        
        let additionalSeparator = UIView(frame: CGRect(origin: CGPoint(x: 0, y: cell.frame.height - separatorThickness), size: CGSize(width: cell.frame.size.width, height: separatorThickness)))
        
        additionalSeparator.backgroundColor = separatorBackgroundColor
        
        additionalSeparator.tag = 42
        
        cell.addSubview(additionalSeparator)
    }

}
