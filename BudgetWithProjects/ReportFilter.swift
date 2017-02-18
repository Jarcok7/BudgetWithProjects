//
//  ReportFilter.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 10/29/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class ReportFilter {
    
    var attributeName: String
    var use = false
    var elements: [NSObject] = []
    
    init(attributeName: String) {
        self.attributeName = attributeName
    }
    
    init(reportFilter: ReportFilter) {
        self.attributeName = reportFilter.attributeName
        self.use = reportFilter.use
        self.elements = reportFilter.elements
    }
    
    var description: String {
        get {
            let key = attributeName == "project" ? "shortName" : "name"
            let namesArray: [String] = self.elements.map({$0.value(forKey: key) as! String})
            
            return namesArray.joined(separator: ",")
        }
    }
    
}
