//
//  Category+CoreDataProperties.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/10/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Category {

    @NSManaged var name: String
    @NSManaged var typeValue: Int16
    
    @NSManaged var transactions : NSSet
    
    var type: CategoryType {
        get {
            return CategoryType(rawValue: self.typeValue)!
        }
        set {
            self.typeValue = (newValue.rawValue)
        }
    }

}

enum CategoryType: Int16 {
    case transfer = 1, exchange = 2, loan = 3, loanRepayment = 4, income = 8, expense = 9
}
