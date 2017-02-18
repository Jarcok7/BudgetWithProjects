//
//  UsedCurrency.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/16/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import Foundation
import CoreData


class UsedCurrency: NSManagedObject {

    static func updateRates(_ managedObjectContext: NSManagedObjectContext?) {
    
        let usedCurrencies = UsedCurrency.getUsedCurrencies(managedObjectContext, excludeCurrencies: [])
        let startOfDay = Calendar.current.startOfDay(for: Date())
        
        var needUpdate = false
        var currenciesStrForRequest = ""
        
        var firstPair = true
        
        for usedCurrency in usedCurrencies {
            if let rateDate = usedCurrency.rateDate {
                let ratesDateStartOfDay = Calendar.current.startOfDay(for: rateDate as Date)
                if startOfDay.compare(ratesDateStartOfDay) != .orderedSame {
                    needUpdate = true
                }
            } else {
                needUpdate = true
            }
            
            if firstPair {
                firstPair = false
            } else {
                currenciesStrForRequest = "," + currenciesStrForRequest
            }
            
            currenciesStrForRequest = "%22USD" + usedCurrency.code + "%22" + currenciesStrForRequest
        }
        
        if !needUpdate {
            return
        }
        
        let apiEndPoint = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(" + currenciesStrForRequest + ")&format=json&env=store://datatables.org/alltableswithkeys"
        
        guard let url = URL(string: apiEndPoint) else {
            print("Url is not valid")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        
        let session = URLSession.shared

        let task = session.dataTask(with: urlRequest, completionHandler: {(data, response, error) in
            
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode != 200 {
                    print("Error fetching currencies rates")
                    return
                }
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                guard let exchangeDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    print("Could not convert JSON to dictionary")
                    return
                }
                //print(exchangeDict.description)
                guard let query = exchangeDict["query"] as? [String: AnyObject] else {
                    print("Could not get query")
                    return
                }
                guard let results = query["results"] as? [String: AnyObject] else {
                    print("Could not get results")
                    return
                }
                
                if let rates = results["rate"] as? [[String: AnyObject]] {
    
                    for currency in usedCurrencies {
                        let filteredRates = rates.filter({($0["id"] as? String) == "USD" + currency.code})
                        
                        if currency.code == "USD" {
                            currency.rate = 1
                            currency.rateDate = startOfDay
                            continue
                        }
                        
                        if filteredRates.count != 1 {
                            continue
                        }
                        
                        if let rateStr = filteredRates[0]["Rate"] as? String {
                            if let rate = Float(rateStr) {
                                currency.rate = rate
                            }
                            currency.rateDate = startOfDay
                        }
                        
                    }
                    
                    OperationQueue.main.addOperation({
                        if let managedObjectContext = managedObjectContext {
                            AppDelegate.saveContext(managedObjectContext)
                        }
                    })
                }
            }
            catch {
                print("Error trying to convert JSON to dictionary")
            }
        }) 
        
        task.resume()
    }
    
    static func getUsedCurrencies(_ managedObjectContext: NSManagedObjectContext?, excludeCurrencies: [UsedCurrency]) -> [UsedCurrency] {
        
        if let managedObjectContext = managedObjectContext {
            let fetch: NSFetchRequest<UsedCurrency> = NSFetchRequest(entityName: "UsedCurrency")
            let predicate = NSPredicate(format: "used == YES")
            fetch.predicate = predicate
            let sort = NSSortDescriptor(key: "orderIndex", ascending: true)
            fetch.sortDescriptors = [sort]
            
            do {
                let usedCurrencies = try managedObjectContext.fetch(fetch)
                return usedCurrencies.filter({!excludeCurrencies.contains($0)})
                
            } catch {
                print("Fetch used currencies failed")
                return []
            }
        }
        
        return []
    }
    
    static func getDictJSONFromResorseFile() -> [String:String]?  {
        if let path = Bundle.main.path(forResource: "currencies", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String:String]
                    
                    return jsonResult
                    
                } catch let error as NSError {
                    print(error)
                }
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    static func findOrCreate(byCode code: String, name: String?, managedObjectContext: NSManagedObjectContext, cache: inout [String:UsedCurrency]) -> UsedCurrency? {
        
        if let currency = cache[code] {
            return currency
        }
        
        let fetchRequest: NSFetchRequest<UsedCurrency> = NSFetchRequest()
        
        let entity = NSEntityDescription.entity(forEntityName: "UsedCurrency", in: managedObjectContext)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "code == %@", code)
        fetchRequest.predicate = predicate
        
        do {
            let currencies = try managedObjectContext.fetch(fetchRequest)
            
            if currencies.count > 0 {
                
                cache[code] = currencies[0]
                
                return currencies[0]
            }
            
        } catch {
            print("Fetch currencies failed")
        }
        
        if let currency = NSEntityDescription.insertNewObject(forEntityName: "UsedCurrency", into: managedObjectContext) as? UsedCurrency {
            
            currency.code = code
            currency.name = name ?? ""
            currency.rate = 1
            currency.rateDate = Date() - 24 * 3600
            currency.used = true
            
            cache[code] = currency
            
            return currency
            
        } else {
            return nil
        }
        
    }

}
