//
//  ProjectsTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/28/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class ProjectsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UITextFieldDelegate, ProjectTableViewCellDelegate {
    
    var detailItem: TempTransaction?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
 
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject))
        self.navigationItem.rightBarButtonItems = [addButton]
        
        if detailItem == nil {
            self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        }
        
        self.navigationItem.title = "Projects"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let project = detailItem?.project {
            let projects = self.fetchedResultsController.fetchedObjects! 
            if let index = projects.index(of: project) {
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
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "New project", message: nil, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { [weak self] (textField) -> Void in
            textField.delegate = self
            textField.placeholder = "Short name (8 characters)"
            textField.autocapitalizationType = .sentences
        })
        
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Long name (optional)"
            textField.autocapitalizationType = .sentences
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
            let textFieldShort = alert.textFields![0] as UITextField
            let textFieldLong = alert.textFields![1] as UITextField
            let shortName = textFieldShort.text!
            let longName = textFieldLong.text!
            
            if shortName == "" {
                return
            }
            
            let context = self.fetchedResultsController.managedObjectContext
            let entity = self.fetchedResultsController.fetchRequest.entity!
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: context)
            
            // If appropriate, configure the new managed object.
            // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
            newManagedObject.setValue(shortName, forKey: "shortName")
            newManagedObject.setValue(longName, forKey: "name")
            
            let projects = self.fetchedResultsController.fetchedObjects! 
            
            if let lastProject = projects.last {
                newManagedObject.setValue(lastProject.orderIndex.intValue + 1, forKey: "orderIndex")
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
    
    // MARK: - UITFDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string) as NSString
        return newString.length <= 8
    }
    
    // MARK - conform to ProjectTableViewCellDelegate protocol
    
    func didChangeSwitchState(_ sender: ProjectsTableViewCell, isOn: Bool) {
        
        let context = self.fetchedResultsController.managedObjectContext
        
        let indexPath = self.tableView.indexPath(for: sender)
        let projects = self.fetchedResultsController.fetchedObjects! 
        let project = projects[(indexPath! as NSIndexPath).row]
        project.open = isOn
        self.tableView.reloadRows(at: [indexPath!], with: .automatic)
        
        AppDelegate.saveContext(context)
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as! ProjectsTableViewCell
        cell.openSwitch.isHidden = !(detailItem == nil)
        let object = self.fetchedResultsController.object(at: indexPath) 
        self.configureCell(cell, withObject: object)
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
        let context = self.fetchedResultsController.managedObjectContext
        var projects = self.fetchedResultsController.fetchedObjects! 
        
        let fromProject = projects[(fromIndexPath as NSIndexPath).row]
        
        self.fetchedResultsController.delegate = nil
        
        projects.remove(at: (fromIndexPath as NSIndexPath).row)
        projects.insert(fromProject, at: (toIndexPath as NSIndexPath).row)
        
        var i = 0
        for project in projects {
            i = i + 1
            project.setValue(i, forKey: "orderIndex")
        }
        
        AppDelegate.saveContext(context)
        
        NSFetchedResultsController<Project>.deleteCache(withName: "Project")
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let context = self.fetchedResultsController.managedObjectContext
        let projects = self.fetchedResultsController.fetchedObjects!
        let project = projects[indexPath.row]
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            // Edit account name
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Edit project", message: nil, preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { [weak self] (textField) -> Void in
                textField.delegate = self
                textField.text = project.shortName
                textField.placeholder = "Short name (8 characters)"
                textField.autocapitalizationType = .sentences
            })
            
            alert.addTextField(configurationHandler: { (textField) -> Void in
                textField.text = project.name
                textField.placeholder = "Long name (optional)"
                textField.autocapitalizationType = .sentences
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                let textFieldShort = alert.textFields![0] as UITextField
                let textFieldLong = alert.textFields![1] as UITextField
                let shortName = textFieldShort.text!
                let longName = textFieldLong.text!
                
                if shortName == "" {
                    return
                }
                
                project.setValue(shortName, forKey: "shortName")
                project.setValue(longName, forKey: "name")
                
                // Save the context.
                AppDelegate.saveContext(context)
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        
        let delete = UITableViewRowAction(style: .default, title: "Delete") { action, index in
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(project)
            
            AppDelegate.saveContext(context)
        }
        
        if project.transactions.count > 0 {
            return [edit]
        }
        
        return [delete, edit]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailItem = detailItem {
            detailItem.project = self.fetchedResultsController.object(at: indexPath)
            
            self.performSegue(withIdentifier: "unwindToDetailsFromProjects", sender: self)
            
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
    
    func configureCell(_ cell: ProjectsTableViewCell, withObject object: Project) {
        cell.shortName.text = object.shortName
        cell.longName.text = object.name
        cell.openSwitch.isOn = object.open
        cell.delegate = self
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
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Project> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Project> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Project", in: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 0
        
        // Edit the sort key as appropriate.
        let sortDescriptorOpen = NSSortDescriptor(key: "open", ascending: false)
        let sortDescriptorOrderIndex = NSSortDescriptor(key: "orderIndex", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptorOpen, sortDescriptorOrderIndex]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Project>?
    
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
            self.configureCell((tableView.cellForRow(at: indexPath!)! as! ProjectsTableViewCell), withObject: anObject as! Project)
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
