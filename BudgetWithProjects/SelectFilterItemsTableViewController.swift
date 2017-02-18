//
//  SelectFilterItemsTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 10/22/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class SelectFilterItemsTableViewController: UITableViewController {
    
    var items: [NSObject] = []
    var itemsType = ""
    var reportFilter: ReportFilter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let select = UIBarButtonItem(image: #imageLiteral(resourceName: "CheckAll"), style: .plain, target: self, action: #selector(selectAllItems))
        let deselect = UIBarButtonItem(image: #imageLiteral(resourceName: "UncheckAll"), style: .plain, target: self, action: #selector(deselectAllItems))
        
        self.navigationItem.rightBarButtonItems = [deselect, select]

        fillItems()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParentViewController {
                    
            reportFilter.use = (reportFilter.elements.count > 0)
        }
    }
    
    func selectAllItems() {
        reportFilter.elements = items
        tableView.reloadData()
    }
    
    func deselectAllItems() {
        reportFilter.elements.removeAll()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let item = items[indexPath.row]
        let name = item.value(forKey: "name") as! String
        
        var labelText = ""
        
        if itemsType == "Project" {
            let shortName = item.value(forKey: "shortName") as! String
            labelText = shortName + (name == "" ? "" : ": \(name)")
        } else {
            labelText = name
        }
        
        cell.textLabel?.text = labelText
        
        if reportFilter.elements.contains(item) {
            cell.accessoryType = .checkmark
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        
        cell.accessoryType = UITableViewCellAccessoryType.checkmark
        reportFilter.elements.append(items[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        
        cell.accessoryType = UITableViewCellAccessoryType.none
        reportFilter.elements.remove(at: reportFilter.elements.index(of: items[indexPath.row])!)
    }

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
    
    func fillItems() {
        
        if itemsType == "" {
            return
        }
        
        if let managedObjectContext = managedObjectContext {
            let fetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: itemsType)
            
            if itemsType == "Project" {
                let sortDescriptorOpen = NSSortDescriptor(key: "open", ascending: false)
                let sortDescriptorOrderIndex = NSSortDescriptor(key: "orderIndex", ascending: true)                
                fetch.sortDescriptors = [sortDescriptorOpen, sortDescriptorOrderIndex]
            } else if itemsType == "Account"  {
                let sort = NSSortDescriptor(key: "orderIndex", ascending: true)
                fetch.sortDescriptors = [sort]
            } else if itemsType == "Category"  {
                let sortType = NSSortDescriptor(key: "typeValue", ascending: true)
                let sortName = NSSortDescriptor(key: "name", ascending: true)
                fetch.sortDescriptors = [sortType, sortName]
            }
            
            do {
                items = try managedObjectContext.fetch(fetch)
                
            } catch {
                print("Fetch \(itemsType) failed")
            }
        }
        
    }
}
