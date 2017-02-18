//
//  ReportsTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 10/16/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class ReportsTableViewController: UITableViewController {
    
    var filters: [ReportFilter] = []
    
    var standartPeriod: StandartPeriod? = .thisMonth
    
    var period: [Int] = [0, 1, 0]
    
    var startDate: Date = Date().startOfMonth()
    var baseStartDate: Date = Date().startOfMonth()
    var endDate: Date = Date().endOfMonth()
    
    var items: [[String:AnyObject]] = []
    var itemsWithRates: [[String:AnyObject]] = []
    
    var currencies: [UsedCurrency] = []
    var presentCurrency: UsedCurrency?

    @IBOutlet weak var filterBBI: UIBarButtonItem!
    @IBOutlet var periodStepper: UIStepper!
    
    var drilledItem: AnyObject?
    var drillExpense = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fillSettingsFromCurrentVariant()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        currencies = UsedCurrency.getUsedCurrencies(managedObjectContext, excludeCurrencies: [])
        
        if presentCurrency == nil {
            changeCurrency()
        }

        refreshAll()
        
        setPeriodPrompt()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func changeCurrencyTapped(_ sender: UIBarButtonItem) {
        changeCurrency()
        refreshItems()
    }
    
    @IBAction func periodStepperValueChanged(_ sender: UIStepper) {
        startDate = getDateConsideringStepperValue(for: baseStartDate, stepperValue: Int(periodStepper.value))
        endDate = getDateConsideringStepperValue(for: baseStartDate, stepperValue: Int(periodStepper.value) + 1) - 1
        
        standartPeriod = nil
        
        setPeriodPrompt()
        
        refreshAll()
    }
    
    @IBAction func reportVariantsTapped(_ sender: UIBarButtonItem) {
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Report variants", message: nil, preferredStyle: .actionSheet)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and add first option action
        let saveAsNew: UIAlertAction = UIAlertAction(title: "Save as new", style: .default)
        { action -> Void in
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "New variant", message: nil, preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (textField) -> Void in
                textField.placeholder = "Variant name"
                textField.autocapitalizationType = .sentences
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
                let textField = alert.textFields![0] as UITextField
                let variantName = textField.text!
                
                if variantName == "" {
                    return
                }
                
                var variants = ReportVariant.loadVariants()
                
                for index in 0..<variants.endIndex {
                    variants[index].current = false
                }
                
                let newVariant = ReportVariant(type: .balance, name: variantName)
                
                newVariant.current = true
                
                if let _standartPeriod = self.standartPeriod {
                    newVariant.standartPeriod = _standartPeriod
                }
                
                newVariant.period = self.period
                newVariant.startDate = self.startDate
                
                newVariant.reportsFilters = self.filters
                newVariant.currencyCode = self.presentCurrency?.code
                
                variants.append(newVariant)
                
                ReportVariant.save(variants)
                
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        }
        actionSheetController.addAction(saveAsNew)
        
        //Create and add a second option action
        var variants = ReportVariant.loadVariants()
        if let currentIndex = variants.index(where: { $0.current }) {
            
            let currentVariant = variants[currentIndex]
            
            if !currentVariant.predestinated {
                let updateCurrent: UIAlertAction = UIAlertAction(title: "Update '\(currentVariant.name)'", style: .default)
                { action -> Void in
                    
                    let askAlert = UIAlertController(title: "Updating variant", message: "Do you want to update '\(currentVariant.name)' variant?", preferredStyle: .alert)
                    
                    askAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    askAlert.addAction(UIAlertAction(title: "Update", style: .destructive, handler: { [unowned self] (action) -> Void in
                        
                        currentVariant.currencyCode = self.presentCurrency?.code
                        
                        if let _standartPeriod = self.standartPeriod {
                            currentVariant.standartPeriod = _standartPeriod
                        }
                        
                        currentVariant.period = self.period
                        currentVariant.reportsFilters = self.filters
                        currentVariant.startDate = self.startDate
                        
                        let range = Range(uncheckedBounds: (currentIndex, currentIndex + 1))
                        variants.replaceSubrange(range, with: [currentVariant])
                        
                        ReportVariant.save(variants)
                    }))
                    
                    self.present(askAlert, animated: true, completion: nil)
                    
                }
                actionSheetController.addAction(updateCurrent)
            }
        }
        
        //Create and add a third option action
        let selectAnother: UIAlertAction = UIAlertAction(title: "Select another", style: .default)
        { action -> Void in
            
            let reportVariantsNC = self.storyboard?.instantiateViewController(withIdentifier: "ReportVariantsNC") as! UINavigationController
            
            reportVariantsNC.modalPresentationStyle = .overCurrentContext
            
            self.present(reportVariantsNC, animated: true, completion: nil)
            
        }
        actionSheetController.addAction(selectAnother)
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            
        } else if let category = item["item"] as? Category {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            cell.textLabel?.text = category.name
            
            let sumTotal = item["sumTotal"] as? Double ?? 0
            cell.detailTextLabel?.text = Transaction.getSumPresentation(sumTotal, currencyCode: presentCurrency?.code ?? "")
            
            if sumTotal > 0 {
                cell.detailTextLabel?.textColor = SumViewController.plusColor()
            } else if sumTotal < 0 {
                cell.detailTextLabel?.textColor = SumViewController.minusColor()
            }
            
            addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.lightGray)
            
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
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Drill", message: nil, preferredStyle: .actionSheet)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        //Create and add first option action
        let takeDescriptionsAction: UIAlertAction = UIAlertAction(title: "Descriptions", style: .default)
        { action -> Void in
            
            self.drilledItem = item["item"]
            self.drillExpense = item["expense"] as? Bool ?? true
            self.performSegue(withIdentifier: "drillReportItem", sender: self)
            
        }
        actionSheetController.addAction(takeDescriptionsAction)
        //Create and add a second option action
        let chooseTransactionsAction: UIAlertAction = UIAlertAction(title: "Transactions", style: .default)
        { action -> Void in
            
            self.drilledItem = item["item"]
            self.drillExpense = item["expense"] as? Bool ?? true
            self.performSegue(withIdentifier: "showTransactionForReportItem", sender: self)
            
        }
        actionSheetController.addAction(chooseTransactionsAction)
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
        
        self.tableView.deselectRow(at: indexPath, animated: false)

    }
    
    //MARK: - Helpers
    func addHeaderSeparator(cell: UITableViewCell, separatorThickness: CGFloat, separatorBackgroundColor: UIColor) {
        
        let additionalSeparator = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: cell.frame.size.width, height: separatorThickness)))
        
        additionalSeparator.backgroundColor = separatorBackgroundColor
        cell.addSubview(additionalSeparator)
    }
    
    func addFooterSeparator(cell: UITableViewCell, separatorThickness: CGFloat, separatorBackgroundColor: UIColor) {
        
        let additionalSeparator = UIView(frame: CGRect(origin: CGPoint(x: 0, y: cell.frame.height - separatorThickness), size: CGSize(width: cell.frame.size.width, height: separatorThickness)))
        
        additionalSeparator.backgroundColor = separatorBackgroundColor
        cell.addSubview(additionalSeparator)
    }
    
    func changeCurrency() {
        if currencies.count != 0 {
            if presentCurrency == nil {
                presentCurrency = currencies.first!
            }
            else {
                let i = currencies.index(of: presentCurrency!)!
                if i == currencies.count - 1 {
                    presentCurrency = currencies.first!
                }
                else {
                    presentCurrency = currencies[i + 1]
                }
            }
        }
    }
    
    func refreshItems(needSorting: Bool = true) {
        items.removeAll()
        
        items = Transaction.getReportInfo(managedObjectContext: managedObjectContext!, itemsWithRates: itemsWithRates, presentCurrency: presentCurrency, needSorting: needSorting)
        
        tableView.reloadData()
        
    }
    
    func refreshAll() {
        itemsWithRates = Transaction.fetchReportInfoWithRates(managedObjectContext: managedObjectContext!, groupBy: "category",predicate: getPredicate())
        refreshItems()
    }
    
    func getDateConsideringStepperValue(for oldDate: Date, stepperValue: Int) -> Date {
        
        var newDate = oldDate
        
        if period[0] != 0 {
            if let _newDate = Calendar.current.date(byAdding: .year, value: period[0] * stepperValue, to: newDate) {
                newDate = _newDate
            }
        }
        
        if period[1] != 0 {
            if let _newDate = Calendar.current.date(byAdding: .month, value: period[1] * stepperValue, to: newDate) {
                newDate = _newDate
            }
        }
        
        if period[2] != 0 {
            if let _newDate = Calendar.current.date(byAdding: .day, value: period[2] * stepperValue, to: newDate) {
                newDate = _newDate
            }
        }
        
        return newDate
        
    }
    
    func setPeriodPrompt() {
        
        if let _standartPeriod = standartPeriod {
            
            switch _standartPeriod {
            case StandartPeriod.allTime:
                self.navigationItem.prompt = "All time"
            case StandartPeriod.thisYear:
                self.navigationItem.prompt = "This year"
            case StandartPeriod.thisMonth:
                self.navigationItem.prompt = "This month"
            case StandartPeriod.thisWeek:
                self.navigationItem.prompt = "This week"
            case StandartPeriod.thisDay:
                self.navigationItem.prompt = "This day"
            }
            
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            let strStartDate = dateFormatter.string(from: startDate)
            let strEndDate = dateFormatter.string(from: endDate)
            
            self.navigationItem.prompt = "\(strStartDate) - \(strEndDate)"
        }
        
    }
    
    func getPredicate() -> NSPredicate? {
        
        var predicates: [NSPredicate] = []
        
        for filter in filters {
            if filter.use {
                if filter.elements.count > 0 {
                    predicates.append(NSPredicate(format: "\(filter.attributeName) IN %@", filter.elements))
                } else {
                    predicates.append(NSPredicate(format: "\(filter.attributeName) == nil"))
                }
            }
        }
        
        if standartPeriod != StandartPeriod.allTime {
            predicates.append(NSPredicate(format: "(timeStamp >= %@) AND (timeStamp <= %@)", startDate as NSDate, endDate as NSDate))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    func fillSettingsFromCurrentVariant() {
        if let currentVariant = ReportVariant.getCurrentVariant() {
            
            if let _standartPeriod = currentVariant.standartPeriod {
                
                standartPeriod = _standartPeriod
                
                let params = StandartPeriod.periodParameters(standartPeriod: _standartPeriod)
                
                self.startDate = params.startDate
                self.period = params.period
            
            } else {
                self.startDate = currentVariant.startDate
                self.period = currentVariant.period
            }
            
            self.baseStartDate = self.startDate
            periodStepper.value = 0
            self.endDate = getDateConsideringStepperValue(for: baseStartDate, stepperValue: Int(periodStepper.value) + 1) - 1
            
            if let _currencyCode = currentVariant.currencyCode {
                if let _currency = currencies.first(where: { $0.code == _currencyCode }) {
                    self.presentCurrency = _currency
                }
            }

        }
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromReportsToFilter" {
            let filterNC = segue.destination as! UINavigationController
            let filterVC = filterNC.topViewController as! ReportsFilterTableViewController
            
            if let filter = filters.first(where: {$0.attributeName == "account"}) {
                filterVC.accountRF = ReportFilter(reportFilter: filter)
            } else {
                filterVC.accountRF = ReportFilter(attributeName: "account")
            }
            
            if let filter = filters.first(where: {$0.attributeName == "project"}) {
                filterVC.projectRF = ReportFilter(reportFilter: filter)
            } else {
                filterVC.projectRF = ReportFilter(attributeName: "project")
            }
            
            if let filter = filters.first(where: {$0.attributeName == "category"}) {
                filterVC.categoryRF = ReportFilter(reportFilter: filter)
            } else {
                filterVC.categoryRF = ReportFilter(attributeName: "category")
            }
        } else if segue.identifier == "fromReportsToPeriod" {
            let periodNC = segue.destination as! UINavigationController
            let periodVC = periodNC.topViewController as! SelectPeriodViewController
            
            periodVC.standartPeriod = self.standartPeriod
            periodVC.startDate = self.startDate
            periodVC.period = self.period
            periodVC.endDate = self.endDate
            
        } else if segue.identifier == "drillReportItem" {
            
            guard let _drilledItem = drilledItem as? Category else {
                return
            }
            
            let drillNC = segue.destination as! UINavigationController
            let drillVC = drillNC.topViewController as! ReportsDrillTableViewController
            
            let drillBy = "category"
            let groupBy = "desc"
            
            drillVC.groupBy = groupBy
            drillVC.presentCurrency = presentCurrency
            drillVC.managedObjectContext = managedObjectContext!
            drillVC.navigationItem.title = _drilledItem.name
            
            if let filtersPredicate = getPredicate() {
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [filtersPredicate, NSPredicate(format: "\(drillExpense ? "sum < 0" : "sum > 0") AND \(drillBy) == %@", _drilledItem)])
                
                drillVC.predicate = predicate
                
            } else {
                drillVC.predicate = NSPredicate(value: false)
            }
            
        } else if segue.identifier == "showTransactionForReportItem" {
            
            guard let _drilledItem = drilledItem as? Category else {
                return
            }
            
            let transactionsNC = segue.destination as! UINavigationController
            let transactionsVC = transactionsNC.topViewController as! MasterViewController
            
            let drillBy = "category"
            
            if let filtersPredicate = self.getPredicate() {
                
                transactionsVC.drillmode = true
                
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [filtersPredicate, NSPredicate(format: "\(drillExpense ? "sum < 0" : "sum > 0") AND \(drillBy) == %@", _drilledItem)])
                
                transactionsVC.drillPredicate = predicate
                
                transactionsVC.navigationItem.leftBarButtonItems = [UIBarButtonItem(title: "Close", style: .plain, target: transactionsVC, action: #selector(transactionsVC.cancel))]
                
            }
        }
    }
    
    @IBAction func unwindToReportsFromFilter(_ sender: UIStoryboardSegue) {
        
        let filtersVC = sender.source as! ReportsFilterTableViewController
        
        filters.removeAll()
        
        filters.append(filtersVC.accountRF)
        filters.append(filtersVC.projectRF)
        filters.append(filtersVC.categoryRF)
        
        if filters.contains(where: {$0.use}) {
            filterBBI.image = #imageLiteral(resourceName: "FilterFilled")
        } else {
            filterBBI.image = #imageLiteral(resourceName: "Filter")
        }
    }
    
    @IBAction func unwindToReportsFromPeriod(_ sender: UIStoryboardSegue) {
        
        let periodVC = sender.source as! SelectPeriodViewController
        
        self.startDate = periodVC.startDate
        self.baseStartDate = self.startDate
        periodStepper.value = 0
        
        self.standartPeriod = periodVC.standartPeriod
        self.period = periodVC.period
        self.endDate = periodVC.endDate
        
        setPeriodPrompt()

    }
    
    @IBAction func unwindToReportsFromVariants(_ sender: UIStoryboardSegue) {
      
        fillSettingsFromCurrentVariant()
        
        setPeriodPrompt()
            
        refreshAll()
        
    }

}

extension Date {
    func startOfYear() -> Date {
        let comp: DateComponents = Calendar.current.dateComponents([.year, .hour], from: Calendar.current.startOfDay(for: self))
        return Calendar.current.date(from: comp)!
    }
    
    func endOfYear() -> Date {
        var comp: DateComponents = Calendar.current.dateComponents([.year, .day, .hour], from: Calendar.current.startOfDay(for: self))
        comp.year = 1
        comp.day = -1
        return Calendar.current.date(byAdding: comp, to: self.startOfYear())! + (3600 * 24 - 1)
    }
    
    func startOfMonth() -> Date {
        let comp: DateComponents = Calendar.current.dateComponents([.year, .month, .hour], from: Calendar.current.startOfDay(for: self))
        return Calendar.current.date(from: comp)!
    }
    
    func endOfMonth() -> Date {
        var comp: DateComponents = Calendar.current.dateComponents([.month, .day, .hour], from: Calendar.current.startOfDay(for: self))
        comp.month = 1
        comp.day = -1
        return Calendar.current.date(byAdding: comp, to: self.startOfMonth())! + (3600 * 24 - 1)
    }
    
    func startOfWeek() -> Date {
        let comp: DateComponents = Calendar.current.dateComponents([.year, .month, .weekOfMonth, .hour], from: Calendar.current.startOfDay(for: self))
        return Calendar.current.date(from: comp)!
    }
    
    func endOfWeek() -> Date {
        var comp: DateComponents = Calendar.current.dateComponents([.weekOfYear, .day, .hour], from: Calendar.current.startOfDay(for: self))
        comp.weekOfYear = 1
        comp.day = -1
        return Calendar.current.date(byAdding: comp, to: self.startOfWeek())! + (3600 * 24 - 1)
    }
    
    func endOfDay() -> Date {

        return Calendar.current.startOfDay(for: self) + (3600 * 24 - 1)
    }
}
