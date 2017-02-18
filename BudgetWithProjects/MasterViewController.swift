//
//  MasterViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 5/30/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: TransactionDetailViewController? = nil
    
    var firstFactIndexPath: IndexPath? = nil
//    var isBeingLoaded = true
    
    var drillmode = false
    
    var drillPredicate: NSPredicate?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var planBBI: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if !drillmode {
            let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
            
            self.navigationItem.leftBarButtonItems = [refreshBtn]
        } else {
            self.navigationItem.rightBarButtonItems?.remove(at: 1)
        }
        
        self.navigationItem.title = "Transactions"
        
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.searchBarStyle = .minimal
        tableView.tableHeaderView = searchController.searchBar

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /*
        if self.isBeingLoaded {
            // Perform an action that will only be done once
            if let _firstFactIndexPath = firstFactIndexPath {
                tableView.scrollToRow(at: _firstFactIndexPath, at: .top, animated: false)
            }
            
            self.isBeingLoaded = false
        }
        */
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.object(at: indexPath) 
                let navController = segue.destination as! UINavigationController
                let controller = navController.topViewController as! TransactionDetailViewController
                
                let tempTransaction = TempTransaction(transaction: object)
                controller.detailItem = tempTransaction
                controller.transaction = object
            }
        } else if segue.identifier == "addNew" {
            let context = self.fetchedResultsController.managedObjectContext

            let controller = (segue.destination as! UINavigationController).topViewController as! SumViewController
          
            let tempTransaction = TempTransaction()
            tempTransaction.timeStamp = Date()
            
            controller.detailItem = tempTransaction
            controller.managedObjectContext = context
            
        } else if segue.identifier == "planNew" {
            let context = self.fetchedResultsController.managedObjectContext
            
            let controller = (segue.destination as! UINavigationController).topViewController as! SumViewController
            
            let tempTransaction = TempTransaction()
            tempTransaction.plan = true
            
            controller.detailItem = tempTransaction
            controller.managedObjectContext = context
            
        }
    }
    
    @IBAction func unwindToTransactionList(_ sender: UIStoryboardSegue) {
        let context = self.fetchedResultsController.managedObjectContext
        do {
            try context.save()
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "Transaction")
        } catch {
            
            fatalError("Failure to fetch transactions: \(error)")
        }
    }
    
    func refresh() {
        tableView.reloadData()
    }
    
    func cancel() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionTableViewCell
        let object = self.fetchedResultsController.object(at: indexPath) 
        self.configureCell(cell, withObject: object)
        
        if firstFactIndexPath == nil && !object.plan {
            firstFactIndexPath = indexPath
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = self.fetchedResultsController.managedObjectContext
            
            let object = self.fetchedResultsController.object(at: indexPath)
            context.delete(object)
            
            if let corrObject = object.correspondingTransaction {
                context.delete(corrObject)
            }
                
            AppDelegate.saveContext(context)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.name
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = header.textLabel?.font.withSize(14)
        header.textLabel?.textColor = UIColor.darkGray
        header.textLabel?.textAlignment = .center
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    func configureCell(_ cell: TransactionTableViewCell, withObject object: Transaction) {
        
        if let projCode = object.project?.shortName {
            cell.longDesc.text = projCode + (object.desc.isEmpty ? "" : ": ") + object.desc
        } else {
            cell.longDesc.text = object.desc
        }
        
        cell.shortDesc.textColor = UIColor.darkText
        cell.sum.textColor = UIColor.darkGray
        
        if object.category?.type == CategoryType.transfer {
            cell.sum.text = Transaction.getSumPresentation(object.sum > 0 ? object.sum : -object.sum, currencyCode: object.usedCurrency?.code)
            cell.account.text = (object.account?.name)! + (object.sum < 0 ? " → " : " ← ") + (object.correspondingTransaction?.account?.name)!
            cell.shortDesc.text = object.category?.name
        }
        else if object.category?.type == CategoryType.exchange {
            if object.account == object.correspondingTransaction?.account {
                cell.account.text = object.account?.name
            } else {
                cell.account.text = (object.account?.name)! + (object.sum < 0 ? " → " : " ← ") + (object.correspondingTransaction?.account?.name)!
            }
            
            cell.shortDesc.text = Transaction.getSumPresentation(object.sum, currencyCode: object.usedCurrency?.code)
            cell.sum.text = Transaction.getSumPresentation((object.correspondingTransaction?.sum)!, currencyCode: object.correspondingTransaction?.usedCurrency?.code)
            if object.sum < 0 {
                cell.shortDesc.textColor = SumViewController.minusColor()
                cell.sum.textColor = SumViewController.plusColor()
            }
            else if object.sum > 0 {
                cell.shortDesc.textColor = SumViewController.plusColor()
                cell.sum.textColor = SumViewController.minusColor()
            }
        }
        else {
            cell.sum.text = Transaction.getSumPresentation(object.sum, currencyCode: object.usedCurrency?.code)
            if object.sum < 0 {
                cell.sum.textColor = SumViewController.minusColor()
            }
            else if object.sum > 0 {
                cell.sum.textColor = SumViewController.plusColor()
            }
            cell.account.text = object.account?.name
            cell.shortDesc.text = object.category?.name
        }
        
        
    }

    // MARK: - Fetched results controller
    
    func getPredicate(searchText: String = "") -> NSPredicate {
        let basePredicate = NSPredicate(format: "subsidiary == NO")
        
        var predicates = [basePredicate]
        
        if let _drillPredicate = drillPredicate {
            predicates.append(_drillPredicate)
        }
        
        if !searchText.isEmpty {
            let searchWords = searchText.components(separatedBy: " ")
            let searchPredicates = searchWords.map({ NSPredicate(format: "sortDesc CONTAINS[cd] %@", $0) })
            
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: searchPredicates)
            predicates.append(searchPredicate)
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
    }

    var fetchedResultsController: NSFetchedResultsController<Transaction> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Transaction> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Transaction", in: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sdPlan = NSSortDescriptor(key: "plan", ascending: false)
        let sdPlanWithoutDate = NSSortDescriptor(key: "planWithoutDate", ascending: false)
        let sdTimeStamp = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sdPlan, sdPlanWithoutDate, sdTimeStamp]
        
        fetchRequest.predicate = getPredicate()
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: "dayForSection", cacheName: nil) //drillmode ? nil : "Transaction"
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            
             fatalError("Failure to fetch transactions: \(error)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Transaction>?
    
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
                self.configureCell(tableView.cellForRow(at: indexPath!)! as! TransactionTableViewCell, withObject: anObject as! Transaction)
            case .move:
                //tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

    func filterContentForSearchText(searchText: String) {
        
        fetchedResultsController.fetchRequest.predicate = getPredicate(searchText: searchText)
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            
            fatalError("Failure to fetch transactions: \(error)")
        }
        
        tableView.reloadData()
    }

}

/*
extension MasterViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
*/

extension MasterViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filterContentForSearchText(searchText: "")
    }
}


