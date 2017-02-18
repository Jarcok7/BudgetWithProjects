//
//  AccountsTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/21/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class AccountsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, AccountsTableViewCellDelegate {
    
    var detailItem: TempTransaction?
    var editDetailMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if detailItem == nil {
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject)), self.editButtonItem]
        }
        
        self.navigationItem.title = "Accounts"
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertNewObject(_ sender: AnyObject) {
        
        // Input new account name
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "New account", message: nil, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Account name"
            textField.autocapitalizationType = .sentences
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            let accountName = textField.text!
            
            if accountName == "" {
                return
            }
            
            let context = self.fetchedResultsController.managedObjectContext
            let entity = self.fetchedResultsController.fetchRequest.entity!
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: context)
            
            // If appropriate, configure the new managed object.
            // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
            newManagedObject.setValue(accountName, forKey: "name")
            
            let accounts = self.fetchedResultsController.fetchedObjects! 
            
            if let lastAccount = accounts.last {
                newManagedObject.setValue(lastAccount.orderIndex.intValue + 1, forKey: "orderIndex")
            }
            else {
                newManagedObject.setValue(1, forKey: "orderIndex")
            }
            
            // Save the context.
            AppDelegate.saveContext(context)
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as! AccountsTableViewCell
        let object = self.fetchedResultsController.object(at: indexPath) 
        self.configureCell(cell, withObject: object)
        return cell
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
    
        let context = self.fetchedResultsController.managedObjectContext
        var accounts = self.fetchedResultsController.fetchedObjects! 
        
        let fromAccount = accounts[(fromIndexPath as NSIndexPath).row]
        
        self.fetchedResultsController.delegate = nil
        
        accounts.remove(at: (fromIndexPath as NSIndexPath).row)
        accounts.insert(fromAccount, at: (toIndexPath as NSIndexPath).row)
        
        var i = 0
        for account in accounts {
            i = i + 1
            account.setValue(i, forKey: "orderIndex")
        }
        
        AppDelegate.saveContext(context)
        
        NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "Account")
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            fatalError("Failure to fetch accounts: \(error)")
        }
        
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        let accounts = self.fetchedResultsController.fetchedObjects!
        if accounts.count == 1 {
            return false
        }
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let context = self.fetchedResultsController.managedObjectContext
        let accounts = self.fetchedResultsController.fetchedObjects!
        let account = accounts[indexPath.row]
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            // Edit account name
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Edit account", message: nil, preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (textField) -> Void in
                textField.text = account.name
                textField.placeholder = "Account name"
                textField.autocapitalizationType = .sentences
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                let textField = alert.textFields![0] as UITextField
                let accountName = textField.text!
                
                if accountName == "" {
                    return
                }
                
                account.setValue(accountName, forKey: "name")
                
                // Save the context.
                AppDelegate.saveContext(context)
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        
        let delete = UITableViewRowAction(style: .default, title: "Delete") { action, index in
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(account)
            
            AppDelegate.saveContext(context)
        }
        
        if account.transactions.count > 0 {
            return [edit]
        }
        
        return [delete, edit]
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailItem = detailItem {
            let correspondAccount = self.fetchedResultsController.object(at: indexPath)
            
            if editDetailMode {
                
                detailItem.correspondingAccount = correspondAccount
                self.performSegue(withIdentifier: "unwindToDetailsFromAccounts", sender: self)
                
            } else if detailItem.category?.type == .transfer {
                
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let detailVC: TransactionDetailViewController = storyboard.instantiateViewController(withIdentifier: "DetailVC") as! TransactionDetailViewController
                
                detailItem.correspondingAccount = correspondAccount
                detailItem.correspondingSum = -detailItem.sum
                detailItem.correspondingUsedCurrency = detailItem.usedCurrency
                detailVC.detailItem = detailItem
                
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK - Accounts table view cell delegate
    
    func didChangeSwitchState(_ sender: AccountsTableViewCell, isOn: Bool) {
        let accounts = self.fetchedResultsController.fetchedObjects!
        
        if accounts.filter({ $0.open }).count == 1 && !isOn {
            
            let alert = UIAlertController(title: nil, message: "Must be at least one open account", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            sender.openSwitch.isOn = true
        } else {
            let context = self.fetchedResultsController.managedObjectContext
            let indexPath = self.tableView.indexPath(for: sender)
            let account = accounts[(indexPath! as NSIndexPath).row]
            account.open = isOn
            self.tableView.reloadRows(at: [indexPath!], with: .automatic)
            
            AppDelegate.saveContext(context)
        }
    }
    
    func configureCell(_ cell: AccountsTableViewCell, withObject object: Account) {
        cell.nameLabel.text = object.name
        cell.openSwitch.isOn = object.open
        cell.delegate = self
        if detailItem?.category?.type == .transfer {
            cell.openSwitch.isHidden = true
            if let _account = detailItem?.account {
                if object == _account {
                    cell.isUserInteractionEnabled = false
                    cell.nameLabel
                        .textColor = UIColor.gray
                }
            }
        }
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
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Account> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Account> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Account", in: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 0
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "orderIndex", ascending: true)
        let openSortDescriptor = NSSortDescriptor(key: "open", ascending: false)
        
        fetchRequest.sortDescriptors = [openSortDescriptor, sortDescriptor]
        
        if let _ = detailItem {
            fetchRequest.predicate = NSPredicate(format: "open == YES")
        }
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            fatalError("Failure to fetch accounts: \(error)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Account>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.configureCell(tableView.cellForRow(at: indexPath!)! as! AccountsTableViewCell, withObject: anObject as! Account)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
     // In the simplest, most efficient, case, reload the table view.
     self.tableView.reloadData()
     }
     */

}
