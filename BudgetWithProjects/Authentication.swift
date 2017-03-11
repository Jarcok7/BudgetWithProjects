//
//  Authentication.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 3/8/17.
//  Copyright © 2017 Jarco Katsalay. All rights reserved.
//

import Foundation

class Authentication {
    func used() -> Bool {
        
        return (try? passwordItem.readPassword()) == nil ? false : true
    }
    
    func on(newPassword: String) {
        do {
            
            // Save the password for the new item.
            try passwordItem.savePassword(newPassword)
        } catch {
            fatalError("Error setting password - \(error)")
        }
    }
    
    private var _passwordItem: KeychainPasswordItem?
    
    var passwordItem: KeychainPasswordItem {
        
        if _passwordItem == nil  {
            _passwordItem = KeychainPasswordItem(service: "BudgetWithProject", account: "Default")
        }
        
        return _passwordItem!
    }
}
