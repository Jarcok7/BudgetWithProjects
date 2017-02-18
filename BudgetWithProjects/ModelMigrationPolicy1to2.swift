//
//  ModelMigrationPolicy1to2.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 12/26/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import CoreData

class ModelMigrationPolicy1to2: NSEntityMigrationPolicy {
    func getSortDesc(_ sourceInstance: NSManagedObject) -> NSString {
        
        let account = sourceInstance.value(forKey: "account") as! NSManagedObject
        let accountName = account.value(forKey: "name") as! String
        
        let category = sourceInstance.value(forKey: "category") as! NSManagedObject
        let categoryName = category.value(forKey: "name") as! String
        
        let currency = sourceInstance.value(forKey: "usedCurrency") as! NSManagedObject
        let currencyCode = currency.value(forKey: "code") as! String
        
        let desc = sourceInstance.value(forKey: "desc") as! String
        
        var projectName = ""
        var projectShortName = ""
        
        if let project = sourceInstance.value(forKey: "project") as? NSManagedObject {
            projectName = project.value(forKey: "name") as! String
            projectShortName = project.value(forKey: "shortName") as! String
        }
        
        var corrAccountName = ""
        var corrCurrencyCode = ""
        
        if let corrTr = sourceInstance.value(forKey: "correspondingTransaction") as? NSManagedObject {
            let account = corrTr.value(forKey: "account") as! NSManagedObject
            corrAccountName = account.value(forKey: "name") as! String

            
            let currency = corrTr.value(forKey: "usedCurrency") as! NSManagedObject
            corrCurrencyCode = currency.value(forKey: "code") as! String
        }
        
        let sum = String(sourceInstance.value(forKey: "sum") as! Double)
        
        return "\(accountName),\(categoryName),\(currencyCode),\(projectName),\(projectShortName),\(corrAccountName),\(corrCurrencyCode),\(sum),\(desc)" as NSString
    }
}
