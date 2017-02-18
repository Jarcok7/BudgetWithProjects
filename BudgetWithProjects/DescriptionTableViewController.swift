//
//  DescriptionTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/20/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class DescriptionTableViewController: UITableViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var descriptionTF: UITextField!
    
    var filteredDesc:[[String:AnyObject]]! = nil
    
    var detailItem: TempTransaction?
    var editDetailMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Description"
        
        let buttons = [UIBarButtonItem(title: (editDetailMode ? "Done" :"Next"), style: .done, target: self, action: #selector(moveToNextVC))]
        
        self.navigationItem.rightBarButtonItems = buttons
        
        //filteredDesc = getDescriptionsFilteredOn("")
        
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let desc = detailItem?.desc {
            descriptionTF.text = desc
            filteredDesc = getDescriptionsFilteredOn(desc)
        }
    }

    @IBAction func descriptionChanged(_ sender: UITextField) {
        
        descChanged()
    }
    
    func descChanged() {
        
        let oldFilteredDescCount = filteredDesc.count
        
        filteredDesc = getDescriptionsFilteredOn(descriptionTF.text ?? "")
        
        var deleteIndexPahts: [IndexPath] = []
        var insertIndexPahts: [IndexPath] = []
        
        for index in 0..<oldFilteredDescCount {
            deleteIndexPahts.append(IndexPath(item: index, section: 0))
        }
        
        for index in 0..<filteredDesc.count {
            insertIndexPahts.append(IndexPath(item: index, section: 0))
        }
        
        tableView.beginUpdates()
        self.tableView.deleteRows(at: deleteIndexPahts, with: .none)
        self.tableView.insertRows(at: insertIndexPahts, with: .none)
        tableView.endUpdates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filteredDesc.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        descriptionTF.becomeFirstResponder()
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerView.frame.size.height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)

        let object = filteredDesc[(indexPath as NSIndexPath).row]
        
        cell.textLabel?.text = (object["desc"] as? String)
        cell.detailTextLabel?.text = String(describing: (object["count"])!)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = filteredDesc[(indexPath as NSIndexPath).row]
        
        descriptionTF.text = (object["desc"] as? String)
        
        descChanged()
    }
    
    // MARK: - MOC
    var managedObjectContext: NSManagedObjectContext? {
        
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
    
    // MARK: - Fetch request
    
    func getDescriptions() -> [[String:AnyObject]] {
        
        let aFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Transaction", in: self.managedObjectContext!)
        aFetchRequest.entity = entity
        
        // Set NSExpressionDescription
        var expDesc = [AnyObject]()
        expDesc.append("desc" as AnyObject)
        
        let descExpr = NSExpression(forKeyPath: "desc")
        let countExpr = NSExpressionDescription()
        //let countVariableExpr = NSExpression(forVariable: "count")
        
        countExpr.name = "count"
        countExpr.expression = NSExpression(forFunction: "count:", arguments: [ descExpr ])
        countExpr.expressionResultType = .integer64AttributeType
        
        // Append the description to our array
        expDesc.append(countExpr)
        
        // Set the batch size to a suitable number.
        aFetchRequest.fetchBatchSize = 0
        
        aFetchRequest.propertiesToFetch = expDesc
        
        aFetchRequest.propertiesToGroupBy = ["desc"]
        
        let predicate = NSPredicate(format: "desc != '' AND subsidiary == NO AND category == %@", detailItem?.category ?? Category())
        aFetchRequest.predicate = predicate
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "desc", ascending: false)
        
        aFetchRequest.sortDescriptors = [sortDescriptor]
        
        aFetchRequest.resultType = .dictionaryResultType
        
        do {
            if var desc = try self.managedObjectContext?.fetch(aFetchRequest) as? [[String:AnyObject]] {
                
                desc.sort(by: {(item1: [String:AnyObject], item2: [String:AnyObject]) -> Bool in
                    
                    let count1 = item1["count"] as? Int
                    let count2 = item2["count"] as? Int
                    
                    return count1! > count2!
                })
                return desc
            }
        } catch {
            print("Fetch descriptions failed")
        }
        
        return [[String:AnyObject]]()
    }
    
    func getDescriptionsFilteredOn(_ filterStr: String) -> [[String:AnyObject]] {
        if allDescriptions == nil {
            allDescriptions = getDescriptions()
        }
        
        if filterStr.isEmpty {
            return allDescriptions
        }
        
        let filteredDescription = allDescriptions.filter({item in
            let desc = (item["desc"] as? String ?? "").lowercased()
            return desc.contains(filterStr.lowercased())
        })
        
        return filteredDescription
    }
    
    var allDescriptions: [[String:AnyObject]]! = nil

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    
    func moveToNextVC() {
        
        detailItem?.desc = descriptionTF.text!
        
        if editDetailMode {
            self.performSegue(withIdentifier: "unwindToDetailsFromDescription", sender: self)
        } else {
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            
            if detailItem?.category?.type == CategoryType.loan {
                let vc = storyboard.instantiateViewController(withIdentifier: "DatePickerVC") as! DatePickerViewController
                vc.timeStamp = Calendar.current.startOfDay(for: Date())
                vc.detailItem = detailItem
                vc.editMode = false
                vc.repaymentMode = true
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                let vc = storyboard.instantiateViewController(withIdentifier: "DetailVC") as! TransactionDetailViewController
                vc.detailItem = detailItem
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
