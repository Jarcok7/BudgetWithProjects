//
//  Project+CoreDataProperties.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/28/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Project {

    @NSManaged var shortName: String
    @NSManaged var name: String
    @NSManaged var open: Bool
    @NSManaged var orderIndex: NSNumber
    
    @NSManaged var transactions : NSSet

}
