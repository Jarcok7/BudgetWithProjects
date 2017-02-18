//
//  ReportVariant.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 11/12/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class ReportVariant: NSObject, NSCoding {
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("reportVariant")
    
    var name = ""
    var reportsFilters: [ReportFilter] = []
    var startDate: Date = Date().startOfMonth()
    var period: [Int] = [0, 1, 0]
    var type: ReportType
    var predestinated = false
    var current = false
    var currencyCode: String?
    var standartPeriod: StandartPeriod?
    
    required init(type: ReportType, name: String) {
        self.type = type
        self.name = name
        
        super.init()
    }
    
    required convenience init? (coder aDecoder: NSCoder) {
        
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String else {
            return nil
        }
        
        guard let typeRowValue = aDecoder.decodeObject(forKey: PropertyKey.typeKey) as? Int8 else {
            return nil
        }
        
        let type = ReportType(rawValue: typeRowValue)
        
        self.init(type: type!, name: name)
        
        self.reportsFilters = aDecoder.decodeObject(forKey: PropertyKey.reportsFiltersKey) as? [ReportFilter] ?? []
        self.startDate = aDecoder.decodeObject(forKey: PropertyKey.startDateKey) as? Date ?? Date().startOfMonth()
        self.period = aDecoder.decodeObject(forKey: PropertyKey.periodKey) as? [Int] ?? [0, 1, 0]
        self.predestinated = aDecoder.decodeBool(forKey: PropertyKey.predestinatedKey)
        self.current = aDecoder.decodeBool(forKey: PropertyKey.currentKey)
        self.currencyCode = aDecoder.decodeObject(forKey: PropertyKey.currencyCodeKey) as? String
        self.standartPeriod = StandartPeriod(rawValue: aDecoder.decodeObject(forKey: PropertyKey.standartPeriodKey) as? Int ?? -1)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(reportsFilters, forKey: PropertyKey.reportsFiltersKey)
        aCoder.encode(startDate, forKey: PropertyKey.startDateKey)
        aCoder.encode(period, forKey: PropertyKey.periodKey)
        aCoder.encode(type.rawValue, forKey: PropertyKey.typeKey)
        aCoder.encode(predestinated, forKey: PropertyKey.predestinatedKey)
        aCoder.encode(current, forKey: PropertyKey.currentKey)
        aCoder.encode(currencyCode, forKey: PropertyKey.currencyCodeKey)
        aCoder.encode(standartPeriod?.rawValue, forKey: PropertyKey.standartPeriodKey)
    }
    
    static func loadVariants() -> [ReportVariant] {
        return NSKeyedUnarchiver.unarchiveObject(withFile: ReportVariant.ArchiveURL.path) as? [ReportVariant] ?? []
    }
    
    static func getCurrentVariant() -> ReportVariant? {
        let variants = ReportVariant.loadVariants()
        
        return variants.first(where: { $0.current })
    }
    
    static func save(_ reportVariants: [ReportVariant]) {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(reportVariants, toFile: ReportVariant.ArchiveURL.path)
        
        if !isSuccessfulSave {
            print("Failed to save report variants...")
        }
    }
}

enum ReportType: Int8 {
    case balance = 1
}

struct PropertyKey {
    static let nameKey = "name"
    static let reportsFiltersKey = "reportsFilters"
    static let startDateKey = "startDate"
    static let periodKey = "period"
    static let typeKey = "type"
    static let predestinatedKey = "predestinated"
    static let currentKey = "current"
    static let currencyCodeKey = "currencyCode"
    static let standartPeriodKey = "standartPeriod"
    
}
