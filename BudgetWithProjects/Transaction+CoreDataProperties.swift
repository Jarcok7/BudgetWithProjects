//
//  Transaction+CoreDataProperties.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/18/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Transaction {

    @NSManaged var timeStamp: Date?
    @NSManaged var desc: String
    @NSManaged var sortDesc: String
    @NSManaged var id: String
    @NSManaged var sum: Double
    @NSManaged var subsidiary: Bool
    @NSManaged var plan: Bool
    @NSManaged var planWithoutDate: Bool
    @NSManaged var category: Category?
    @NSManaged var account: Account?
    @NSManaged var project: Project?
    @NSManaged var usedCurrency: UsedCurrency?
    @NSManaged var correspondingTransaction: Transaction?

}
