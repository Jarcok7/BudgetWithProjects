//
//  MainTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 10/12/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class MainTableViewController: UITableViewController, MainTableViewCellDelegate {
    
    struct AccountCurrencyInfo {
        var account: Account?
        var currency: UsedCurrency?
        var sum: Double
    }
    
    @IBOutlet weak var planFactSC: UISegmentedControl!
    
    var sumInfo: [[String:AnyObject]] = []
    
    var accountsCurrenciesInfo: [AccountCurrencyInfo] = []
    
    var accounts: [Account] = []
    var currencies: [UsedCurrency] = []
    
    var presentCurrency: UsedCurrency!
    
    var initiatedTransactionRow: Int?
    var initiatedTransactionPlusMinus: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        accounts = Account.getAccounts(managedObjectContext: managedObjectContext)
        currencies = UsedCurrency.getUsedCurrencies(managedObjectContext, excludeCurrencies: [])
        
        if presentCurrency == nil || !currencies.contains(presentCurrency) {
            presentCurrency = nil
            changeCurrency()
        }
        
        updateSumInfo()
        fillAccountsCurrenciesInfo()
        
        tableView.reloadData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func planFactChanged(_ sender: UISegmentedControl) {
        updateSumInfo()
        fillAccountsCurrenciesInfo()
        tableView.reloadData()
    }

    @IBAction func changeCurrencyTapped(_ sender: AnyObject) {
        changeCurrency()
        fillAccountsCurrenciesInfo()
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return accountsCurrenciesInfo.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let info = accountsCurrenciesInfo[indexPath.row]
        
        if let account = info.account {
            if let currency = info.currency {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath) as! MainTableViewCell
                
                cell.subviews.filter({$0.tag == 42}).first?.removeFromSuperview()
                cell.subviews.filter({$0.tag == 43}).first?.removeFromSuperview()
                
                cell.textLabel?.text = Transaction.getSumPresentation(info.sum, currencyCode: currency.code)
                cell.detailTextLabel?.text = Transaction.getSumPresentation(info.sum * Double(presentCurrency.rate) / Double(currency.rate), currencyCode: presentCurrency.code)
                
                if info.sum > 0 {
                    cell.textLabel?.textColor = SumViewController.plusColor()
                } else if info.sum < 0 {
                    cell.textLabel?.textColor = SumViewController.minusColor()
                }
                
                cell.delegate = self
                cell.row = indexPath.row
                
                addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.lightGray)
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as! MainTableViewCell
                
                cell.subviews.filter({$0.tag == 42}).first?.removeFromSuperview()
                cell.subviews.filter({$0.tag == 43}).first?.removeFromSuperview()
                
                cell.textLabel?.text = account.name
                cell.detailTextLabel?.text = Transaction.getSumPresentation(info.sum, currencyCode: presentCurrency.code)
                
                cell.delegate = self
                cell.row = indexPath.row
                
                if indexPath.row != 0 {
                    addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.black)
                }
                
                return cell
            }
        } else {
            if let currency = info.currency {
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TotalCurrencyCell", for: indexPath)
                
                cell.subviews.filter({$0.tag == 42}).first?.removeFromSuperview()
                cell.subviews.filter({$0.tag == 43}).first?.removeFromSuperview()
                
                cell.textLabel?.text = Transaction.getSumPresentation(info.sum, currencyCode: currency.code)
                cell.detailTextLabel?.text = Transaction.getSumPresentation(info.sum * Double(presentCurrency.rate) / Double(currency.rate), currencyCode: presentCurrency.code)
                
                if info.sum > 0 {
                    cell.textLabel?.textColor = SumViewController.plusColor()
                } else if info.sum < 0 {
                    cell.textLabel?.textColor = SumViewController.minusColor()
                }
                
                addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.lightGray)
                
                if indexPath.row == accountsCurrenciesInfo.count - 1 {
                    addFooterSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.black)
                }
                
                return cell
            } else {
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TotalCell", for: indexPath)
                
                cell.subviews.filter({$0.tag == 42}).first?.removeFromSuperview()
                cell.subviews.filter({$0.tag == 43}).first?.removeFromSuperview()
                
                cell.textLabel?.text = "Totals"
                cell.detailTextLabel?.text = Transaction.getSumPresentation(info.sum, currencyCode: presentCurrency?.code)
                
                if indexPath.row != 0 {
                    addHeaderSeparator(cell: cell, separatorThickness: CGFloat(0.5), separatorBackgroundColor: UIColor.black)
                }
                
                return cell
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "fromMainToSum" {
            
            let controller = (segue.destination as! UINavigationController).topViewController as! SumViewController
            
            let info = accountsCurrenciesInfo[initiatedTransactionRow!]
            
            let tempTransaction = TempTransaction()
            tempTransaction.timeStamp = (planFactSC.selectedSegmentIndex == 1 ? nil : Date())
            tempTransaction.account = info.account
            tempTransaction.usedCurrency = info.currency
            tempTransaction.initiateFromMain = true
            
            tempTransaction.plan = (planFactSC.selectedSegmentIndex == 1)
            
            controller.detailItem = tempTransaction
            controller.managedObjectContext = managedObjectContext
            controller.plusMinus = initiatedTransactionPlusMinus
            
        } else if segue.identifier == "fromMainToSumPlan" {
            
            let controller = (segue.destination as! UINavigationController).topViewController as! SumViewController
            
            let tempTransaction = TempTransaction()
            tempTransaction.plan = true
            tempTransaction.initiateFromMain = true
            
            controller.detailItem = tempTransaction
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue) {
        do {
            try managedObjectContext?.save()
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "Transaction")
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error.localizedDescription)")
            abort()
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
    
    // MARK: - Helpers
    
    func addHeaderSeparator(cell: UITableViewCell, separatorThickness: CGFloat, separatorBackgroundColor: UIColor) {
        
        let additionalSeparator = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: cell.frame.size.width, height: separatorThickness)))
        
        additionalSeparator.backgroundColor = separatorBackgroundColor
        additionalSeparator.tag = 42
        cell.addSubview(additionalSeparator)
    }
    
    func addFooterSeparator(cell: UITableViewCell, separatorThickness: CGFloat, separatorBackgroundColor: UIColor) {
        
        let additionalSeparator = UIView(frame: CGRect(origin: CGPoint(x: 0, y: cell.frame.height - separatorThickness), size: CGSize(width: cell.frame.size.width, height: separatorThickness)))
        
        additionalSeparator.backgroundColor = separatorBackgroundColor
        additionalSeparator.tag = 43
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
    
    func updateSumInfo() {
        var predicate = ""
        
        switch planFactSC.selectedSegmentIndex {
        case 0:
            predicate = "plan == NO"
        case 1:
            predicate = "plan == YES"
        case 2:
            predicate = ""
        default:
            predicate = ""
        }
        
        sumInfo = Transaction.getSumInfo(managedObjectContext: managedObjectContext!, predicate: predicate)
    }
    
    func fillAccountsCurrenciesInfo() {
        
        accountsCurrenciesInfo = []
        var currenciesTotal = [UsedCurrency: Double]()
        var totalSum: Double = 0
        
        for account in accounts {
            var _accountsCurrenciesInfo: [AccountCurrencyInfo] = []
            var accountSum: Double = 0
            for currency in currencies {
                let sum = Transaction.getSum(forAccount: account, forCurrency: currency, sumInfo: sumInfo, managedObjectContext: managedObjectContext!)
                
                if sum == 0 {
                    continue
                }
                
                let sumInPresentCurrency = sum * Double(presentCurrency.rate) / Double(currency.rate)
                accountSum += sumInPresentCurrency
                _accountsCurrenciesInfo.append(AccountCurrencyInfo(account: account, currency: currency, sum: sum))
                
                currenciesTotal[currency] = (currenciesTotal[currency] ?? 0) + sum
                totalSum += sumInPresentCurrency
            }
            
            if account.open || accountSum != 0 {
                accountsCurrenciesInfo.append(AccountCurrencyInfo(account: account, currency: nil, sum: accountSum))
                accountsCurrenciesInfo += _accountsCurrenciesInfo
            }
        }
        
        accountsCurrenciesInfo.append(AccountCurrencyInfo(account: nil, currency: nil, sum: totalSum))
        
        for (currency, sum) in currenciesTotal {
            accountsCurrenciesInfo.append(AccountCurrencyInfo(account: nil, currency: currency, sum: sum))
        }
    }
    
    // MARK: - Conform to MainTableViewCellDelegate protocol
    func transactionInitiated(cell: MainTableViewCell, plus: Bool) {
        if let row = cell.row {
            initiatedTransactionRow = row
            
            initiatedTransactionPlusMinus = (plus ? 1 : -1)
            
            performSegue(withIdentifier: "fromMainToSum", sender: self)
        }
    }

}
