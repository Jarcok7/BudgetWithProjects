//
//  TempTransaction.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 9/21/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import Foundation

class TempTransaction {
    var timeStamp: Date?
    var desc: String = ""
    var id: String = ""
    var sum: Double = 0.0
    var subsidiary: Bool = false
    var plan: Bool = false
    var category: Category?
    var account: Account?
    var project: Project?
    var usedCurrency: UsedCurrency?
    var correspondingTransaction: Transaction?
    var correspondingAccount: Account?
    var correspondingUsedCurrency: UsedCurrency?
    var correspondingSum: Double = 0.0
    var repaymentDate: Date?
    var initiateFromMain = false
    
    init() {
        
    }
    
    init(transaction: Transaction) {
        
        self.timeStamp = transaction.timeStamp as Date?
        self.desc = transaction.desc
        self.id = transaction.id
        self.sum = transaction.sum
        self.subsidiary = transaction.subsidiary
        self.plan = transaction.plan
        self.category = transaction.category
        self.account = transaction.account
        self.project = transaction.project
        self.usedCurrency = transaction.usedCurrency
        self.correspondingTransaction = transaction.correspondingTransaction
        self.correspondingAccount = transaction.correspondingTransaction?.account
        self.correspondingUsedCurrency = transaction.correspondingTransaction?.usedCurrency
        self.correspondingSum = transaction.correspondingTransaction?.sum ?? 0.0
    }
    
    func fillTransaction(_ transaction: Transaction) {
        transaction.timeStamp = self.timeStamp
        transaction.desc = self.desc
        transaction.id = self.id
        transaction.sum = self.sum
        transaction.subsidiary = self.subsidiary
        transaction.plan = self.plan
        transaction.planWithoutDate = (transaction.timeStamp == nil) && transaction.plan
        transaction.category = self.category
        transaction.account = self.account
        transaction.project = self.project
        transaction.usedCurrency = self.usedCurrency
        transaction.correspondingTransaction = self.correspondingTransaction
    }
    
}
