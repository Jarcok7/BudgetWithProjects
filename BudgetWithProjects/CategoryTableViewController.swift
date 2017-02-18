//
//  CategoryTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/11/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class CategoryTableViewController: UITableViewController, CategoryTableViewCellDelegate {
    
    var detailItem: TempTransaction?
    var editDetailMode = false
    var categories:[Category] = []
    var filteredCategories:[Category] = []
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Categories"
        
        var buttons = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject))]
        if detailItem == nil {
            buttons.append(self.editButtonItem)
        }
        
        self.navigationItem.rightBarButtonItems = buttons
        
        fillCategories()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        definesPresentationContext = !editDetailMode
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let category = detailItem?.category {
            if let index = filteredCategories.index(of: category) {
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertNewObject(_ sender: AnyObject) {
        
        // Input new account name
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "New category", message: nil, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Category name"
            textField.autocapitalizationType = .sentences
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        if let di = detailItem {
            addAlertActionForAC(alertControler: alert, title: "Save", type: (di.sum > 0 ? 8 : 9))
        }
        else {
            addAlertActionForAC(alertControler: alert, title: "Income", type: 8)
            addAlertActionForAC(alertControler: alert, title: "Expense", type: 9)
        }
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func addAlertActionForAC(alertControler alert: UIAlertController, title: String, type: Int) {
        alert.addAction(UIAlertAction(title: title, style: .default, handler: { [unowned self] (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            let categoryName = textField.text!
            
            if categoryName == "" {
                return
            }
            
            let context = self.managedObjectContext!

            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
            
            // If appropriate, configure the new managed object.
            // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
            newManagedObject.setValue(categoryName, forKey: "name")
            newManagedObject.setValue(type, forKey: "typeValue")
            
            // Save the context.
            AppDelegate.saveContext(context)
            self.fillCategories()
            self.tableView.reloadData()
            }))
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredCategories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! CategoryTableViewCell
        let object = filteredCategories[indexPath.row]
        self.configureCell(cell, withObject: object)
        return cell
    }
    
    func configureCell(_ cell: CategoryTableViewCell, withObject object: Category) {
        cell.nameLable.text = object.name
        
        cell.addDescButton.isHidden = (detailItem == nil || editDetailMode || object.typeValue < 8)
        
        cell.delegate = self
        
        if object.typeValue < 8 {
            cell.backgroundColor = UIColor.groupTableViewBackground
        } else {
            cell.backgroundColor = UIColor.white
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let category = self.filteredCategories[indexPath.row]
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            // Edit account name
            
            let context = self.managedObjectContext!
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Edit category", message: nil, preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (textField) -> Void in
                textField.text = category.name
                textField.placeholder = "Category name"
                textField.autocapitalizationType = .sentences
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                let textField = alert.textFields![0] as UITextField
                let categoryName = textField.text!
                
                if categoryName == "" {
                    return
                }
                
                category.setValue(categoryName, forKey: "name")
                
                // Save the context.
                AppDelegate.saveContext(context)
                self.tableView.reloadData()
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        
        let delete = UITableViewRowAction(style: .default, title: "Delete") { action, index in
            let context = self.managedObjectContext!
            context.delete(category)
            self.filteredCategories.remove(at: indexPath.row)
            
            AppDelegate.saveContext(context)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        if category.transactions.count > 0 {
            return [edit]
        }
        
        return [delete, edit]
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let category = filteredCategories[(indexPath as NSIndexPath).row]
        
        let notDeleteType = [CategoryType.exchange, CategoryType.transfer, CategoryType.loan, CategoryType.loanRepayment]
        
        if notDeleteType.contains(category.type) {
            return false
        }
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailItem = detailItem {
            detailItem.category = filteredCategories[indexPath.row]
            
            if editDetailMode {
                self.performSegue(withIdentifier: "unwindToDetailsFromCategories", sender: self)
                
            } else if detailItem.category?.type == CategoryType.transfer {
                
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let accountsVC: AccountsTableViewController = storyboard.instantiateViewController(withIdentifier: "AccountsVC") as! AccountsTableViewController
                
                accountsVC.detailItem = detailItem
                
                self.navigationController?.pushViewController(accountsVC, animated: true)
                
            } else if detailItem.category?.type == CategoryType.exchange {
                
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let sumVC: SumViewController = storyboard.instantiateViewController(withIdentifier: "SumVC") as! SumViewController
                
                sumVC.detailItem = detailItem
                sumVC.managedObjectContext = managedObjectContext
                sumVC.exchangeCurrencyMode = true
                
                self.navigationController?.pushViewController(sumVC, animated: true)
                
            } else if detailItem.category?.type == CategoryType.loan || detailItem.category?.type == CategoryType.loanRepayment {
                
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                
                let descriptionVC: DescriptionTableViewController = storyboard.instantiateViewController(withIdentifier: "DescriptionVC") as! DescriptionTableViewController
                
                descriptionVC.detailItem = detailItem
                
                self.navigationController?.pushViewController(descriptionVC, animated: true)
                
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailVC") as! TransactionDetailViewController
                
                detailVC.detailItem = detailItem
                
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }
    
    // MARK: - Conform to CategoryCellDelegate
    func addDescTapped(_ sender: CategoryTableViewCell) {
        
        let indexPath = self.tableView.indexPath(for: sender)
        
        if let detailItem = detailItem {
            detailItem.category = filteredCategories[indexPath!.row]
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let descriptionVC: DescriptionTableViewController = storyboard.instantiateViewController(withIdentifier: "DescriptionVC") as! DescriptionTableViewController
            
            descriptionVC.detailItem = detailItem
            
            self.navigationController?.pushViewController(descriptionVC, animated: true)
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
    
    func fillCategories() {
        
        let fetchRequest: NSFetchRequest<Category> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Category", in: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 0
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "typeValue", ascending: true)
        
        if let di = detailItem {
            
            let predicate = NSPredicate(format: "typeValue != \(di.sum > 0 ? 9 : 8)")
            fetchRequest.predicate = predicate
        }
        
        fetchRequest.sortDescriptors = [sortDescriptor]
 
        do {
            categories = try managedObjectContext!.fetch(fetchRequest)
            categories.sort(by: { $0.typeValue != $1.typeValue ? $0.typeValue < $1.typeValue : $0.transactions.count > $1.transactions.count})
            
            searchCategories()
            
            self.tableView.reloadData()
            
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error.localizedDescription)")
            abort()
        }
        
    }
    
    func searchCategories(for searchText: String = "") {
        if searchText.isEmpty {
            filteredCategories = categories
        } else {
            filteredCategories = categories.filter({ $0.name.lowercased().contains(searchText.lowercased()) })
        }
    }

}


extension CategoryTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        searchCategories(for: searchController.searchBar.text!)
        self.tableView.reloadData()
    }
}
