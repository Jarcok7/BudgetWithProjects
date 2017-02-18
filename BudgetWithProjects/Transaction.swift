//
//  Transaction.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/18/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import Foundation
import CoreData
import CSVImporter

class Transaction: NSManagedObject {
    
    override func willSave() {
        
        let accountName = self.account?.name ?? ""
        let categoryName = self.category?.name ?? ""
        let currencyCode = self.usedCurrency?.code ?? ""
        let projectName = self.project?.name ?? ""
        let projectShortName = self.project?.shortName ?? ""
        let corrAccountName = self.correspondingTransaction?.account?.name ?? ""
        let corrCurrencyCode = self.correspondingTransaction?.usedCurrency?.code ?? ""
        let sum = String(self.sum)
        
        let sortDesc = "\(accountName),\(categoryName),\(currencyCode),\(projectName),\(projectShortName),\(corrAccountName),\(corrCurrencyCode),\(sum),\(self.desc)"
        
        if self.sortDesc != sortDesc {
            self.sortDesc = sortDesc
        }
    }

    var dayForSection: String {
        get {
            
            if let timeStamp = self.timeStamp {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                dateFormatter.timeStyle = .none
                let strDate = dateFormatter.string(from: timeStamp as Date)
                return self.plan ? "Plan on " + strDate : strDate
            } else {
                return self.plan ? "Plan without date" : "Without date"
            }
        }
    }
    
    static func getSumPresentation(_ sum: Double, currencyCode: String?) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        formatter.currencyCode = currencyCode
        
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        formatter.currencyGroupingSeparator = "\u{2009}"
        
        if let sumPresrntation = formatter.string(from: NSNumber(value: sum)) {
            return sumPresrntation
        }
        
        return String(sum)
    }
    
    static func getSumInfo(managedObjectContext: NSManagedObjectContext, predicate: String = "") -> [[String:AnyObject]] {
        
        let aFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Transaction", in: managedObjectContext)
        aFetchRequest.entity = entity
        
        // Set NSExpressionDescription
        var expDesc = [AnyObject]()
        expDesc.append("account" as AnyObject)
        expDesc.append("usedCurrency" as AnyObject)
        
        let descExpr = NSExpression(forKeyPath: "sum")
        let sumExpr = NSExpressionDescription()
        //let countVariableExpr = NSExpression(forVariable: "count")
        
        sumExpr.name = "sumTotal"
        sumExpr.expression = NSExpression(forFunction: "sum:", arguments: [ descExpr ])
        sumExpr.expressionResultType = .doubleAttributeType
        
        // Append the description to our array
        expDesc.append(sumExpr)
        
        // Set the batch size to a suitable number.
        aFetchRequest.fetchBatchSize = 0
        
        aFetchRequest.propertiesToFetch = expDesc
        
        aFetchRequest.propertiesToGroupBy = ["account", "usedCurrency"]
        
        if !predicate.isEmpty {
            let predicate = NSPredicate(format: predicate)
            aFetchRequest.predicate = predicate
        }
        
        aFetchRequest.resultType = .dictionaryResultType
        
        do {
            if let sumInfo = try managedObjectContext.fetch(aFetchRequest) as? [[String:AnyObject]] {
                
                return sumInfo
            }
        } catch {
            print("Fetch sum info failed")
        }
        
        return [[String:AnyObject]]()
    }
    
    static func fetchIncomeInfo(managedObjectContext: NSManagedObjectContext, groupBy: String, predicate: NSPredicate? = nil) -> [[String:AnyObject]] {
        
        let aFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Transaction", in: managedObjectContext)
        aFetchRequest.entity = entity
        
        // Set NSExpressionDescription
        var properties = [AnyObject]()
        
        let itemExpDesc = NSExpressionDescription()
        itemExpDesc.name = "item"
        itemExpDesc.expression = NSExpression(forKeyPath: groupBy)
        
        properties.append(itemExpDesc)
        
        let rateExpDesc = NSExpressionDescription()
        rateExpDesc.name = "rate"
        rateExpDesc.expression = NSExpression(forKeyPath: "usedCurrency.rate")
        rateExpDesc.expressionResultType = .doubleAttributeType
        
        properties.append(rateExpDesc)
        
        let sumExpr = NSExpression(forKeyPath: "sum")
        let totalSumExpr = NSExpressionDescription()
        
        totalSumExpr.name = "sumTotal"
        
        totalSumExpr.expression = NSExpression(forFunction: "sum:", arguments: [ sumExpr ])
        totalSumExpr.expressionResultType = .doubleAttributeType
        
        // Append the description to our array
        properties.append(totalSumExpr)
        
        // Set the batch size to a suitable number.
        aFetchRequest.fetchBatchSize = 0
        
        aFetchRequest.propertiesToFetch = properties
        
        aFetchRequest.propertiesToGroupBy = [itemExpDesc, rateExpDesc]
        
        let staticPredicate = NSPredicate(format: "category.typeValue != 1 AND category.typeValue != 2 AND plan != YES AND sum > 0")
        
        if let predicate = predicate {
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [staticPredicate, predicate])
            aFetchRequest.predicate = compoundPredicate
        } else {
            aFetchRequest.predicate = staticPredicate
        }
        
        aFetchRequest.resultType = .dictionaryResultType
        
        do {
            if let sumInfo = try managedObjectContext.fetch(aFetchRequest) as? [[String:AnyObject]] {
                
                return sumInfo
            }
        } catch {
            print("Fetch income info failed")
        }
        
        return [[String:AnyObject]]()
    }
    
    static func fetchExpenseInfo(managedObjectContext: NSManagedObjectContext, groupBy: String, predicate: NSPredicate? = nil) -> [[String:AnyObject]] {
        
        let aFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Transaction", in: managedObjectContext)
        aFetchRequest.entity = entity
        
        // Set NSExpressionDescription
        var properties = [AnyObject]()
        
        let itemExpDesc = NSExpressionDescription()
        itemExpDesc.name = "item"
        itemExpDesc.expression = NSExpression(forKeyPath: groupBy)
        
        properties.append(itemExpDesc)
        
        let rateExpDesc = NSExpressionDescription()
        rateExpDesc.name = "rate"
        rateExpDesc.expression = NSExpression(forKeyPath: "usedCurrency.rate")
        rateExpDesc.expressionResultType = .doubleAttributeType
        
        properties.append(rateExpDesc)
        
        let sumExpr = NSExpression(forKeyPath: "sum")
        let totalSumExpr = NSExpressionDescription()
        
        totalSumExpr.name = "sumTotal"
        
        totalSumExpr.expression = NSExpression(forFunction: "sum:", arguments: [ sumExpr ])
        totalSumExpr.expressionResultType = .doubleAttributeType
        
        // Append the description to our array
        properties.append(totalSumExpr)
        
        // Set the batch size to a suitable number.
        aFetchRequest.fetchBatchSize = 0
        
        aFetchRequest.propertiesToFetch = properties
        
        aFetchRequest.propertiesToGroupBy = [itemExpDesc, rateExpDesc]
        
        let staticPredicate = NSPredicate(format: "category.typeValue != 1 AND category.typeValue != 2 AND plan != YES AND sum < 0")
        
        if let predicate = predicate {
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [staticPredicate, predicate])
            aFetchRequest.predicate = compoundPredicate
        } else {
            aFetchRequest.predicate = staticPredicate
        }
        
        aFetchRequest.resultType = .dictionaryResultType
        
        do {
            if let sumInfo = try managedObjectContext.fetch(aFetchRequest) as? [[String:AnyObject]] {
                
                return sumInfo
            }
        } catch {
            print("Fetch expense info failed")
        }
        
        return [[String:AnyObject]]()
    }
    
    static func fetchReportInfoWithRates(managedObjectContext: NSManagedObjectContext, groupBy: String, predicate: NSPredicate? = nil) -> [[String:AnyObject]] {
        
        let incomeInfo = Transaction.fetchIncomeInfo(managedObjectContext: managedObjectContext, groupBy: groupBy, predicate: predicate)
        
        let expenseInfo = Transaction.fetchExpenseInfo(managedObjectContext: managedObjectContext, groupBy: groupBy, predicate: predicate)
        
        return incomeInfo + expenseInfo
    }
    
    static func getReportInfo(managedObjectContext: NSManagedObjectContext, itemsWithRates: [[String: AnyObject]], presentCurrency: UsedCurrency?, needSorting: Bool, insertZeroTotals: Bool = true) -> [[String: AnyObject]] {
        
        var _items = [[String: AnyObject]]()
        
        let presentCurrencyRate = Double(presentCurrency?.rate ?? 1.0)
        
        for itemWithRate in itemsWithRates {
            
            let sumTotal = itemWithRate["sumTotal"] as? Double ?? 0
            
            if let ID = itemWithRate["item"] as? NSManagedObjectID {
                
                if let category = managedObjectContext.object(with: ID) as? Category {
                    
                    let index = _items.index(where: { $0["item"] as? Category == category && ($0["expense"] as? Bool) == (sumTotal < 0) })
                    
                    if index == nil {
                        let item: [String: AnyObject] = ["expense": (sumTotal < 0) as AnyObject, "item": category, "sumTotal": (sumTotal / (itemWithRate["rate"] as? Double ?? 1) * presentCurrencyRate) as AnyObject ]
                        _items.append(item)
                    } else {
                        _items[index!]["sumTotal"] = ((_items[index!]["sumTotal"] as? Double ?? 0) + (itemWithRate["sumTotal"] as? Double ?? 0) / (itemWithRate["rate"] as? Double ?? 1) * presentCurrencyRate) as AnyObject
                    }
                }
            } else if let desc = itemWithRate["item"] as? String {
                
                let index = _items.index(where: { $0["item"] as? String == desc  && ($0["expense"] as? Bool) == (sumTotal < 0) })
                
                if index == nil {
                    let item: [String: AnyObject] = ["expense": (sumTotal < 0) as AnyObject, "item": desc as AnyObject, "sumTotal": (sumTotal / (itemWithRate["rate"] as? Double ?? 1) * presentCurrencyRate) as AnyObject ]
                    _items.append(item)
                } else {
                    _items[index!]["sumTotal"] = ((_items[index!]["sumTotal"] as? Double ?? 0) + (itemWithRate["sumTotal"] as? Double ?? 0) / (itemWithRate["rate"] as? Double ?? 1) * presentCurrencyRate) as AnyObject
                }
            }
        }
        
        var incomeInfo = _items.filter({ Double($0["sumTotal"] as? Double ?? 0) > 0 })
        
        if needSorting {
            incomeInfo.sort(by: {(item1: [String:AnyObject], item2: [String:AnyObject]) -> Bool in
                
                let sumTotal1 = item1["sumTotal"] as? Double
                let sumTotal2 = item2["sumTotal"] as? Double
                
                return sumTotal1! > sumTotal2!
            })
        }
        
        let totalIncome = incomeInfo.map({ Double($0["sumTotal"] as? Double ?? 0) }).reduce(0, +)
        let totalIncomeInfo: [String:AnyObject] = ["groupName": "Income" as AnyObject, "sumTotal": totalIncome as AnyObject]
        
        var expenseInfo = _items.filter({ Double($0["sumTotal"] as? Double ?? 0) < 0 })
        
        if needSorting {
            expenseInfo.sort(by: {(item1: [String:AnyObject], item2: [String:AnyObject]) -> Bool in
                
                let sumTotal1 = item1["sumTotal"] as? Double
                let sumTotal2 = item2["sumTotal"] as? Double
                
                return sumTotal1! < sumTotal2!
            })
        }
        
        let totalExpense = expenseInfo.map({ Double($0["sumTotal"] as? Double ?? 0) }).reduce(0, +)
        let totalExpenseInfo: [String:AnyObject] = ["groupName": "Expense" as AnyObject, "sumTotal": totalExpense as AnyObject]
        
        let balance = totalIncome + totalExpense
        let balanceInfo: [String:AnyObject] = ["groupName": "Balance" as AnyObject, "sumTotal": balance as AnyObject]
        
        return (totalIncome == 0 && !insertZeroTotals ? [] : [totalIncomeInfo]) + incomeInfo + (totalExpense == 0 && !insertZeroTotals ? [] : [totalExpenseInfo]) + expenseInfo + ((totalIncome == 0 || totalExpense == 0) && !insertZeroTotals ? [] : [balanceInfo])
    }
    
    static func getAllTransactions(_ managedObjectContext: NSManagedObjectContext?) -> [Transaction] {
        if let managedObjectContext = managedObjectContext {
            let fetch: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
            
            let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
            fetch.sortDescriptors = [sort]
            
            do {
                let transactions = try managedObjectContext.fetch(fetch)
                return transactions
                
            } catch {
                print("Fetch transactions failed")
                return []
            }
        }
        
        return []
    }
    
    static func getCSVData(_ managedObjectContext: NSManagedObjectContext?) -> Data? {
        
        let transactions = Transaction.getAllTransactions(managedObjectContext)
        
        // Creating a string.
        var mailString = ""
        
        mailString.append("Number,Repeat,Date,Planned,Category,Sheet,Description,Account,Currency,Amount,Account,Currency,Amount,ProjectShortName,ProjectName,ProjectIsOpen\n")
        
        for tr in transactions where !tr.subsidiary {
            
            let id = tr.id
            let date = tr.timeStamp?.toString() ?? ""
            let plan = tr.plan ? "1" : ""
            let category = tr.category?.name ?? ""
            let desc = tr.desc
            let account = tr.account?.name ?? ""
            let currency = tr.usedCurrency?.code ?? ""
            let corrAccount = tr.correspondingTransaction?.account?.name ?? ""
            let corrCurrency = tr.correspondingTransaction?.usedCurrency?.code ?? ""
            let corrSum = String(describing: tr.correspondingTransaction?.sum ?? 0)
            let projectShortName = tr.project?.shortName ?? ""
            let projectName = tr.project?.name ?? ""
            let projectIsOpen = ((tr.project?.open ?? false) ? 1 : 0)
            
            mailString.append("\(id),,\(date),\(plan),\"\(category)\",,\"\(desc)\",\"\(account)\",\(currency),\(tr.sum),\"\(corrAccount)\",\(corrCurrency),\(corrSum),\(projectShortName),\(projectName),\(projectIsOpen)\n")
        }
        
        // Converting it to NSData.
        let data = mailString.data(using: String.Encoding.utf8, allowLossyConversion: false)

        return data
    }
    
    static func getSum(forAccount account: Account?, forCurrency currency: UsedCurrency?, sumInfo: [[String:AnyObject]], managedObjectContext: NSManagedObjectContext) -> Double {
        
        let filteredSumInfo = sumInfo.filter({item in
            
            var _account: Account?
            var _currency: UsedCurrency?
            
            if let ID = item["account"] as? NSManagedObjectID {
                _account = managedObjectContext.object(with: ID) as? Account
            }
            if let ID = item["usedCurrency"] as? NSManagedObjectID {
                _currency = managedObjectContext.object(with: ID) as? UsedCurrency
            }
            
            return (_account == account && _currency == currency)
        })
        
        if filteredSumInfo.count == 1 {
            return (filteredSumInfo[0]["sumTotal"] as? Double) ?? 0
        }
        
        return 0
    }
    
    static func loadFileFromDropbox(url: URL, to localUrl: URL, completion: @escaping () -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                do {
                    
                    if FileManager.default.fileExists(atPath: localUrl.path) {
                        try FileManager.default.removeItem(at: localUrl)
                    }
                    
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                    completion()
                } catch (let writeError) {
                    print("error writing file \(localUrl) : \(writeError)")
                }
                
            } else {
                print("Failure: %@", error?.localizedDescription ?? "");
            }
        }
        task.resume()
    }
    
    static func loadDataFromCSV(from localUrl: URL?, moc: NSManagedObjectContext) {
        
        if let url = localUrl {
            
            if let importer = CSVImporter<[String]>(url: url) {
                importer.startImportingRecords { $0 }.onFinish { importedRecords in
                    
                    var n = 1
                    
                    var accounts: [String:Account] = [:]
                    var categories: [String:Category] = [:]
                    var currencies: [String:UsedCurrency] = [:]
                    var projects: [String:Project] = [:]
                    
                    let currencyInfo = UsedCurrency.getDictJSONFromResorseFile()!
                    
                    for record in importedRecords {
                        
                        let plan = record[3] == "1"
                        
                        var date: Date?
                        
                        date = record[2].toDate()
                        
                        if date == nil && !plan {
                            print("Don't get date from \(record[2]) in row \(n)")
                            continue
                        }
                        
                        guard let sum = Double(record[9]) else { print("Don't get sum from \(record[9]) in row \(n)"); continue}
                        
                        guard let account = Account.findOrCreate(byName: record[7], managedObjectContext: moc, cache: &accounts) else { print("Don't get account from \(record[7]) in row \(n)"); continue}
                        
                        guard let category = Category.findOrCreate(byName: record[4], income: sum > 0, managedObjectContext: moc, cache: &categories) else { print("Don't get category from \(record[4]) in row \(n)"); continue}
                        
                        guard let currency = UsedCurrency.findOrCreate(byCode: record[8], name: currencyInfo[record[8]], managedObjectContext: moc, cache: &currencies) else { print("Don't get currency from \(record[8]) in row \(n)"); continue}
                        
                        let project = Project.findOrCreate(byShortName: record[13], name: record[14],isOpen: record[15] == "1" ? true : false, managedObjectContext: moc, cache: &projects)
                        
                        if let newTransaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: moc) as? Transaction {
                            newTransaction.id = UUID().uuidString
                            newTransaction.category = category
                            newTransaction.desc = record[6]
                            newTransaction.timeStamp = date
                            newTransaction.account = account
                            newTransaction.project = project
                            newTransaction.sum = sum
                            newTransaction.usedCurrency = currency
                            newTransaction.plan = plan
                            newTransaction.planWithoutDate = (date == nil)
                            
                            let categoryType = category.type
                            if categoryType == CategoryType.transfer || categoryType == CategoryType.exchange {
                                guard let corrAccount = Account.findOrCreate(byName: record[10], managedObjectContext: moc, cache: &accounts) else { print("Don't get corr. account from \(record[10]) in row \(n)"); continue}
                                
                                guard let corrCurrency = UsedCurrency.findOrCreate(byCode: record[11], name: currencyInfo[record[11]], managedObjectContext: moc, cache: &currencies) else { print("Don't get corr. currency from \(record[11]) in row \(n)"); continue}
                                
                                guard let corrSum = Double(record[12]) else { print("Don't get corr. sum from \(record[12]) in row \(n)"); continue}
                                
                                if let newCorrTransaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: moc) as? Transaction {
                                    newCorrTransaction.id = newTransaction.id
                                    newCorrTransaction.category = category
                                    newCorrTransaction.desc = record[6]
                                    newCorrTransaction.timeStamp = date
                                    newCorrTransaction.account = corrAccount
                                    newCorrTransaction.project = project
                                    newCorrTransaction.sum = corrSum
                                    newCorrTransaction.usedCurrency = corrCurrency
                                    newCorrTransaction.plan = plan
                                    newCorrTransaction.planWithoutDate = (date == nil)
                                    newCorrTransaction.subsidiary = true
                                    
                                    newTransaction.correspondingTransaction = newCorrTransaction
                                    
                                } else {
                                    print("Can't insert new transaction!")
                                    
                                    break
                                }
                                
                            }
                            
                        } else {
                            print("Can't insert new transaction!")
                            
                            break
                        }
                        
                        n = n + 1
                    }
                    
                    do {
                        try moc.save()
                        UsedCurrency.updateRates(moc)
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        print("Unresolved error \(error), \(error.localizedDescription)")
                        abort()
                    }
                    
                }
                
                //return true
            }
            
            //return false
        }
        
        //return false
    }
}

extension String {
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        let date = dateFormatter.date(from: self)
        
        return date
    }
}

extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
        let str = dateFormatter.string(from: self)
        
        return str
        
    }
}
