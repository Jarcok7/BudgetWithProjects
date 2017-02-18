//
//  Project.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/28/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import Foundation
import CoreData


class Project: NSManagedObject {

    static func findOrCreate(byShortName shortName: String, name: String = "", isOpen: Bool, managedObjectContext: NSManagedObjectContext, cache: inout [String:Project]) -> Project? {
        
        if shortName.isEmpty {
            return nil
        }
        
        if let project = cache[shortName] {
            return project
        }
        
        let fetchRequest: NSFetchRequest<Project> = NSFetchRequest()
        
        let entity = NSEntityDescription.entity(forEntityName: "Project", in: managedObjectContext)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "shortName == %@", shortName)
        fetchRequest.predicate = predicate
        
        do {
            let projects = try managedObjectContext.fetch(fetchRequest)
            
            if projects.count > 0 {
                
                cache[shortName] = projects[0]
                
                return projects[0]
            }
            
        } catch {
            print("Fetch accounts failed")
        }
        
        if let project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: managedObjectContext) as? Project {
            
            project.shortName = shortName
            project.name = name
            project.open = isOpen
            
            cache[shortName] = project
            
            return project
            
        } else {
            return nil
        }
        
    }
    

}
