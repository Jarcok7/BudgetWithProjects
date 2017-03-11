//
//  HistoricalRates+CoreDataProperties.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 3/11/17.
//  Copyright © 2017 Jarco Katsalay. All rights reserved.
//

import Foundation
import CoreData


extension HistoricalRates {

    @NSManaged var rateDate: NSDate
    @NSManaged var rate: NSNumber
    @NSManaged var usedCurrency: UsedCurrency

}
