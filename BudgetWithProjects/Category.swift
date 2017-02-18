//
//  Category.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/10/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import Foundation
import CoreData


class Category: NSManagedObject {

    static func createCategory(_ managedObjectContext: NSManagedObjectContext) {
        if let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as? Category {
            
            category.name = "Transfer"
            category.type = CategoryType.transfer
            
        }
        
        if let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as? Category {
            
            category.name = "Currency exchange"
            category.type = CategoryType.exchange
            
        }
        
        if let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as? Category {
            
            category.name = "Loan"
            category.type = CategoryType.loan
            
        }
        
        if let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as? Category {
            
            category.name = "Loan repayment"
            category.type = CategoryType.loanRepayment
            
        }
    }
    
    static func getRepaymentCategory(_ managedObjectContext: NSManagedObjectContext) -> Category? {
        let fetchRequest: NSFetchRequest<Category> = NSFetchRequest()
 
        let entity = NSEntityDescription.entity(forEntityName: "Category", in: managedObjectContext)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "typeValue == 4")
        fetchRequest.predicate = predicate
        
        do {
            let categories = try managedObjectContext.fetch(fetchRequest)
            return categories[0]
            
        } catch {
            print("Fetch categories failed")
        }
        
        return nil
    }
    
    static func findOrCreate(byName name: String, income: Bool, managedObjectContext: NSManagedObjectContext, cache: inout [String:Category]) -> Category? {
        
        if let category = cache[name] {
            return category
        }
        
        let fetchRequest: NSFetchRequest<Category> = NSFetchRequest()
        
        let entity = NSEntityDescription.entity(forEntityName: "Category", in: managedObjectContext)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.predicate = predicate
        
        do {
            let categories = try managedObjectContext.fetch(fetchRequest)
            
            if categories.count > 0 {
                
                cache[name] = categories[0]
                
                return categories[0]
            }
            
        } catch {
            print("Fetch categories failed")
        }
        
        if let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as? Category {
            
            category.name = name
            
            switch name {
            case "Currency exchange":
                category.type = CategoryType.exchange
            case "Transfer":
                category.type = CategoryType.transfer
            case "Loan repayment":
                category.type = CategoryType.loanRepayment
            case "Loan":
                category.type = CategoryType.loan
            default:
                if income {
                    category.type = CategoryType.income
                } else {
                    category.type = CategoryType.expense
                }
            }
            
            cache[name] = category
            
            return category
            
        } else {
            return nil
        }
        
    }
    
}
