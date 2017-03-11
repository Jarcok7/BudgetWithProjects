//
//  MainTabBarController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 3/8/17.
//  Copyright © 2017 Jarco Katsalay. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    let authentication = Authentication()
    var needToCheckAuthentication = true

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        showLoginView()
        
    }
    
    func appWillEnterForeground(_ notification : NSNotification) {
        
        showLoginView()
    }
    
    func appDidEnterBackground(_ notification : NSNotification) {
        
        needToCheckAuthentication = true
    }
    
    func showLoginView() {
        if needToCheckAuthentication && authentication.used() {
            
            guard let passwordViewController = self.storyboard?.instantiateViewController(withIdentifier: "PasswordViewController") as? PasswordViewController else {
                return
            }
            
            passwordViewController.modalPresentationStyle = .overCurrentContext
            
            self.present(passwordViewController, animated: true, completion: nil)
            
            needToCheckAuthentication = false
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
