//
//  Account+CoreDataProperties.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/24/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Account {

    @NSManaged var name: String
    @NSManaged var orderIndex: NSNumber
    @NSManaged var open: Bool
    
    @NSManaged var transactions : NSSet

}
