//
//  Account.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/23/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import Foundation
import CoreData


class Account: NSManagedObject {

    static func getAccounts(managedObjectContext: NSManagedObjectContext?) -> [Account] {
        
        if let managedObjectContext = managedObjectContext {
            let fetch: NSFetchRequest<Account> = NSFetchRequest(entityName: "Account")
            let sort = NSSortDescriptor(key: "orderIndex", ascending: true)
            fetch.sortDescriptors = [sort]
            
            fetch.predicate = NSPredicate(format: "open == YES")
            
            do {
                let accounts = try managedObjectContext.fetch(fetch)
                return accounts
                
            } catch {
                print("Fetch accounts failed")
                return []
            }
        }
        
        return []
    }

    static func findOrCreate(byName name: String, managedObjectContext: NSManagedObjectContext, cache: inout [String:Account]) -> Account? {
        
        if let account = cache[name] {
            return account
        }
        
        let fetchRequest: NSFetchRequest<Account> = NSFetchRequest()
        
        let entity = NSEntityDescription.entity(forEntityName: "Account", in: managedObjectContext)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.predicate = predicate
        
        do {
            let accounts = try managedObjectContext.fetch(fetchRequest)
            
            if accounts.count > 0 {
                
                cache[name] = accounts[0]
                
                return accounts[0]
            }
            
        } catch {
            print("Fetch accounts failed")
        }
        
        if let account = NSEntityDescription.insertNewObject(forEntityName: "Account", into: managedObjectContext) as? Account {
            
            account.name = name
            
            cache[name] = account
            
            return account
            
        } else {
            return nil
        }
        
    }
}
