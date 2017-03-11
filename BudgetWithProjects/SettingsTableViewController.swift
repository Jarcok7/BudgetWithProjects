//
//  SettingsTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 7/16/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, UITextFieldDelegate {
    
    let autentication = Authentication()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        
        useAuthentication.isOn = autentication.used()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loadCSVFromDropbox(_ sender: Any) {
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Dropbox URL input", message: nil, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Dropbox URL"
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            let URLStr = textField.text!
            
            if URLStr == "" {
                return
            }
            
            if let url = URL(string: URLStr) {
                
                let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    Transaction.loadFileFromDropbox(url: url, to: destinationUrl) {
                        Transaction.loadDataFromCSV(from: destinationUrl, moc: self.managedObjectContext!)
                    }
                }
            }
            
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func exportCSV(_ sender: Any) {
        
        guard let data = Transaction.getCSVData(managedObjectContext) else { return }
        
        func configuredMailComposeViewController() -> MFMailComposeViewController {
            let emailController = MFMailComposeViewController()
            emailController.mailComposeDelegate = self
            emailController.setSubject("Export CSV File")
            emailController.setMessageBody("", isHTML: false)
            
            // Attaching the .CSV file to the email.
            emailController.addAttachmentData(data, mimeType: "text/csv", fileName: "Export.csv")
            
            return emailController
        }
        
        let emailViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            
            self.present(emailViewController, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var useAuthentication: UISwitch!
    
    @IBAction func switchUseAuthentication(_ sender: UISwitch) {
        if sender.isOn {
            onAuthentication(message: nil)
        } else {
            offAuthentication(message: nil)
        }
    }

    func onAuthentication(message: String?) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Set password", message: message, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Password (4 digits)"
            textField.autocapitalizationType = .none
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
            textField.delegate = self
        })
        
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Repeat password (4 digits)"
            textField.autocapitalizationType = .none
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
            textField.delegate = self
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] (action) -> Void in self.useAuthentication.isOn = self.autentication.used() }))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
            let textFieldPassword = alert.textFields![0] as UITextField
            let textFieldRepeatPassword = alert.textFields![1] as UITextField
            let password = textFieldPassword.text!
            let repeatPassword = textFieldRepeatPassword.text!
            
            if password.characters.count != 4 {
                self.onAuthentication(message: "Password must contain 4 digits")
                return
            }
            
            if password != repeatPassword {
                self.onAuthentication(message: "Password and repeating password don't match")
                return
            }
            
            self.autentication.on(newPassword: password)
            self.useAuthentication.isOn = self.autentication.used()
            
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func offAuthentication(message: String?) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Enter password", message: message, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Password (4 digits)"
            textField.autocapitalizationType = .none
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
            textField.delegate = self
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] (action) -> Void in self.useAuthentication.isOn = self.autentication.used() } ))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
            let textFieldPassword = alert.textFields![0] as UITextField
            let password = textFieldPassword.text!
            
            let passwordItem = self.autentication.passwordItem
            if let passwordFromKeyChain = try? passwordItem.readPassword() {
                if password != passwordFromKeyChain {
                    self.offAuthentication(message: "Wrong password")
                    return
                } else {
                    try? passwordItem.deleteItem()
                }
            } else {
                try? passwordItem.deleteItem()
            }
            try? passwordItem.deleteItem()
            self.useAuthentication.isOn = self.autentication.used()
            
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITFDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string) as NSString
        return newString.length <= 4
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func unwindToSettingsFromCurrencies(_ sender: UIStoryboardSegue) {
        
        
    }

    // MARK: - MOC
    var managedObjectContext: NSManagedObjectContext? {
        
        if _managedObjectContext != nil {
            return _managedObjectContext!
        }
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if let moc = delegate?.managedObjectContext {
            
            _managedObjectContext = moc
            return _managedObjectContext!
        }
        
        return nil
    }
    
    var _managedObjectContext: NSManagedObjectContext? = nil
}
