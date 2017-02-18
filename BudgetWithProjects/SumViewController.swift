//
//  SumViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 5/31/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class SumViewController: UIViewController, UIPopoverPresentationControllerDelegate, ChooseProjectTVCDelegate, UITextFieldDelegate {

    var detailItem: TempTransaction!
    var sumAsText: String = "0"
    var sum: Double = 0 {
        didSet {
            nextSaveButton.isEnabled = !(sum == 0)
        }
    }
    var plusMinus = -1
    
    var currency: UsedCurrency?
    var account: Account?
    var project: Project?
    
    var currencies: [UsedCurrency] = []
    var accounts: [Account] = []
    var projects: [Project] = []
    var projectsQA: [Project] = []
    
    var sumInfo = [[String: AnyObject]]()
    
    @IBOutlet weak var plusMinusButton: UIButton!
    
    @IBOutlet weak var sumLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var sumInAccountLabel: UILabel!
    
    @IBOutlet weak var rateTipLabel: UILabel!
    
    var nextSaveButton: UIBarButtonItem!
    
    @IBOutlet weak var projectsSC: ProjectsSC!
    var selectedPSCindex: Int = UISegmentedControlNoSegment
    
    var exchangeCurrencyMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - ChooseProjectTVCDelegate
    func projectChosen(_ project: Project) {
        
        self.project = project
        putSelectedProjectInQA(project)
        
    }
    
    func putSelectedProjectInQA(_ project: Project) {
        projectsSC.removeSegment(at: 2, animated: false)
        projectsQA.remove(at: 2)
        projectsSC.insertSegment(withTitle: project.shortName, at: 2, animated: false)
        projectsQA.insert(project, at: 2)
        projectsSC.selectedSegmentIndex = 2
    }
    
    func addProject() {
        insertNewProject()
    }
    
    // MARK: - UITFDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string) as NSString
        return newString.length <= 8
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }

    func cancelTapped() {
        //detailItem.managedObjectContext!.rollback()
        dismiss(animated: true, completion: nil)
    }
    
    func nextTapped() {
        
        if exchangeCurrencyMode {
            self.performSegue(withIdentifier: "fromSumToDetail", sender: self)
        } else {
            self.performSegue(withIdentifier: "fromSumToCategory", sender: self)
        }
    }
    
    func saveTapped() {
        fillDetail()
        self.performSegue(withIdentifier: "unwindToDetailsFromSum", sender: self)
    }
    
    func fillDetail() {
        
        if exchangeCurrencyMode {
            detailItem.correspondingAccount = account
            detailItem.correspondingUsedCurrency = currency
            detailItem.correspondingSum = Double(plusMinus) * sum
        } else {
            detailItem.account = account
            detailItem.usedCurrency = currency
            detailItem.project = project
            detailItem.sum = Double(plusMinus) * sum
        }
    }
    
    @IBAction func plusMinusChange(_ sender: AnyObject) {
        
        plusMinus = -plusMinus
        setSumLabelText()
    }
    
    @IBAction func changeAccount(_ sender: UIButton) {
        changeAccount()
        setAccountDescription()
    }
    
    @IBAction func changeCurrency(_ sender: UIButton) {
        changeCurrency()
        setAccountDescription()
        setSumLabelText()
        setRateTipLable()
    }
    
    @IBAction func changePSC(_ sender: ProjectsSC) {
        
        if projectsSC.currentSelectedSegmentIndex == projectsSC.selectedSegmentIndex {
            
            projectsSC.selectedSegmentIndex = UISegmentedControlNoSegment
            project = nil
            
        } else if projectsSC.numberOfSegments - 1 == projectsSC.selectedSegmentIndex {
            
            //projectsSC.selectedSegmentIndex = selectedPSCindex
            //project = nil
            
            // Show pop app or add new project
            
            if projects.count > 3 {
                
                let chooseProjectVC = storyboard?.instantiateViewController(withIdentifier: "chooseProjectVC") as! ChooseProjectTableViewController
                
                chooseProjectVC.delegate = self
                chooseProjectVC.projectsQA = projectsQA
                chooseProjectVC.managedObjectContext = managedObjectContext
                
                chooseProjectVC.modalPresentationStyle = .popover
                if let popoverController = chooseProjectVC.popoverPresentationController {
                    popoverController.sourceView = sender
                    popoverController.sourceRect = sender.bounds
                    popoverController.permittedArrowDirections = .any
                    popoverController.delegate = self
                }
                present(chooseProjectVC, animated: true, completion: nil)
            } else {
                
                insertNewProject()
            }

        } else if projectsSC.selectedSegmentIndex >= 0 && projectsSC.selectedSegmentIndex <= projectsQA.endIndex {
            
            project = projectsQA[projectsSC.selectedSegmentIndex]
        }
        
        //selectedPSCindex = projectsSC.selectedSegmentIndex
        
    }
    
    // MARK - Helpers
    
    func setView() {
        
        let addNew = (!exchangeCurrencyMode && detailItem.sum == 0) || (exchangeCurrencyMode && detailItem.correspondingSum == 0)
        
        for subview in view.subviews where subview.tag >= 1001 {
            let btn = subview as! UIButton
            btn.addTarget(self, action: #selector(numbersButtonTapped), for: .touchUpInside)
        }
        
        if addNew {
            nextSaveButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextTapped))
            nextSaveButton.isEnabled = false
            
            self.navigationItem.rightBarButtonItems = [nextSaveButton]
            if !exchangeCurrencyMode {
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
                self.navigationItem.leftBarButtonItems = [cancelButton]
            }
        } else {
            nextSaveButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(saveTapped))
            self.navigationItem.rightBarButtonItems = [nextSaveButton]
        }
        
        plusMinusButton.isEnabled = (detailItem.category?.type != CategoryType.exchange)
        projectsSC.isHidden = exchangeCurrencyMode
        rateTipLabel.isHidden = !exchangeCurrencyMode
        
        accounts = Account.getAccounts(managedObjectContext: managedObjectContext)
        projects = getProjects()
        
        if exchangeCurrencyMode {
            currencies = UsedCurrency.getUsedCurrencies(managedObjectContext, excludeCurrencies: detailItem.usedCurrency == nil ? [] : [detailItem.usedCurrency!])
            if let corrCurrency = detailItem.correspondingUsedCurrency {
                currency = corrCurrency
            } else {
                currency = currencies.first
            }
            
            if let corrAccount = detailItem.correspondingAccount {
                account = corrAccount
            } else {
                account = accounts.first
            }
        } else {
            currencies = UsedCurrency.getUsedCurrencies(managedObjectContext, excludeCurrencies: [])
            currency = detailItem.usedCurrency
            account = detailItem.account
            
            if let currency = detailItem.usedCurrency {
                self.currency = currency
            } else {
                currency = currencies.first
            }
            
            if let account = detailItem.account {
                self.account = account
            } else {
                account = accounts.first
            }
        }
        
        if detailItem.sum > 0 {
            sum = exchangeCurrencyMode ? -detailItem.correspondingSum : detailItem.sum
            plusMinus = exchangeCurrencyMode ? -1 : 1
        } else if detailItem.sum < 0 {
            sum = exchangeCurrencyMode ? detailItem.correspondingSum : -detailItem.sum
            plusMinus = exchangeCurrencyMode ? 1 : -1
        }
        
        if sum.truncatingRemainder(dividingBy: 1) == 0 {
            sumAsText = String(Int(sum))
        } else {
            sumAsText = String(sum)
        }
        
        project = detailItem.project
        
        sumInfo = Transaction.getSumInfo(managedObjectContext: self.managedObjectContext, predicate: "plan == NO")
        
        setSumLabelText()
        setAccountDescription()
        setProjectsSC()
        setRateTipLable()
        
        navigationItem.title = detailItem.plan ? "Plan new" : "Add new"
    }
    
    func insertNewProject() {
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "New project", message: nil, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { [weak self] (textField) -> Void in
            textField.delegate = self
            textField.placeholder = "Short name (8 characters)"
            textField.autocapitalizationType = .sentences
            })
        
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Long name (optional)"
            textField.autocapitalizationType = .sentences
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] (action) -> Void in
            let textFieldShort = alert.textFields![0] as UITextField
            let textFieldLong = alert.textFields![1] as UITextField
            let shortName = textFieldShort.text!
            let longName = textFieldLong.text!
            
            if shortName == "" {
                return
            }
                
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Project", into: self.managedObjectContext) as! Project
            
            // If appropriate, configure the new managed object.
            // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
            newManagedObject.setValue(shortName, forKey: "shortName")
            newManagedObject.setValue(longName, forKey: "name")
            
            if let lastProject = self.projects.last {
                newManagedObject.setValue(lastProject.orderIndex.intValue + 1, forKey: "orderIndex")
            }
            else {
                newManagedObject.setValue(1, forKey: "orderIndex")
            }
            
            // Save the context.
            do {
                try self.managedObjectContext.save()
                self.projects = self.getProjects()
                self.project = self.projects.filter({$0.objectID == newManagedObject.objectID}).first
                self.setProjectsSC()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                print("Unresolved error \(error), \(error.localizedDescription)")
                abort()
            }
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func numbersButtonTapped(_ sender: UIButton) {
        
        let btnText = (sender.titleLabel?.text)!
        var sumAsTextLoc = sumAsText
        
        if sender.tag == 1002 {
            if sumAsTextLoc.characters.count <= 1 {
                sumAsTextLoc = "0"
            }
            else {
                sumAsTextLoc = String(sumAsTextLoc.characters.dropLast())
            }
        }
        else if btnText == "0" && sumAsTextLoc == "0" {
            
        }
        else if btnText == "." && sumAsTextLoc.characters.contains(".") {
            
        }
        else if sumAsTextLoc.characters.count == 12 {
            
        }
        else if let index = getSubStringIndexInString(sumAsTextLoc, subStr: ".") , (index + 2) < sumAsTextLoc.characters.count {
            
        }
        else if sumAsTextLoc == "0" && btnText != "0" && btnText != "." {
            sumAsTextLoc = btnText
        }
        else {
            sumAsTextLoc = sumAsTextLoc + btnText
        }
        
        if let sumLoc = Double(sumAsTextLoc) {
            self.sum = sumLoc
            sumAsText = sumAsTextLoc
            setSumLabelText()
        }
        else {
            sumAsTextLoc = sumAsText
        }
        
    }
    
    func setSumLabelText() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        formatter.currencyCode = currency?.code
        
        if (sum.truncatingRemainder(dividingBy: 1)) == 0 {
            formatter.maximumFractionDigits = 0
        }
        else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }
        sumLabel.text = formatter.string(from: NSNumber(value: self.sum * Double(plusMinus)))
        
        if plusMinus < 0 {
            sumLabel.textColor = SumViewController.minusColor()
        }
        else {
            sumLabel.textColor = SumViewController.plusColor()
        }
    }
    
    func setAccountDescription() {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        formatter.currencyCode = currency?.code
        
        let sumInAccount = Transaction.getSum(forAccount: account, forCurrency: currency, sumInfo: sumInfo, managedObjectContext: managedObjectContext)
        
        if (sumInAccount.truncatingRemainder(dividingBy: 1)) == 0 {
            formatter.maximumFractionDigits = 0
        }
        else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }
        
        sumInAccountLabel.text = formatter.string(from: NSNumber(value: sumInAccount))
        
        if sumInAccount <= 0 {
            sumInAccountLabel.textColor = SumViewController.minusColor()
        }
        else {
            sumInAccountLabel.textColor = SumViewController.plusColor()
        }
        
        if account != nil {
            accountLabel.text = account!.name
        }
        
    }
    
    func setProjectsSC() {
        let projectsCount = projects.count
        projectsSC.removeAllSegments()
        projectsQA.removeAll()
        
        if projectsCount == 0 {
            projectsSC.insertSegment(withTitle: "Add new project", at: 0, animated: false)
        }
        else if projectsCount <= 3{
            for proj in projects {
                projectsQA.append(proj)
            }
            
            for proj in projectsQA {
                projectsSC.insertSegment(withTitle: proj.shortName, at: proj.orderIndex.intValue, animated: false)
            }
            
            projectsSC.insertSegment(withTitle: "Add new", at: projectsCount, animated: false)
        } else if projectsCount > 3 {
            projectsQA.append(projects[0])
            projectsQA.append(projects[1])
            projectsQA.append(projects[2])
            
            for proj in projectsQA {
                projectsSC.insertSegment(withTitle: proj.shortName, at: proj.orderIndex.intValue, animated: false)
            }
            
            projectsSC.insertSegment(withTitle: "More", at: 3, animated: false)
            
        }
        
        if let _project = project {
            if let _indexQA = projectsQA.index(of: _project) {
                projectsSC.selectedSegmentIndex = _indexQA
            }
            else {
                putSelectedProjectInQA(_project)
            }
        }
        
    }
    
    func setRateTipLable() {
        if exchangeCurrencyMode {
            
            let sumTip: Double = abs(detailItem.sum) * Double((currency?.rate)!) / Double((detailItem.usedCurrency?.rate)!)
            
            rateTipLabel.text = Transaction.getSumPresentation(abs(detailItem.sum), currencyCode: detailItem.usedCurrency?.code) + " is equal to " + Transaction.getSumPresentation(sumTip, currencyCode: currency?.code)
        }
    }
    
    static func plusColor() -> UIColor {
        return UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
    }
    
    static func minusColor() -> UIColor {
        return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0)
    }
    
    func getSubStringIndexInString(_ str: String, subStr: String) -> Int? {
        
        if let range = str.range(of: subStr) {
            let index: Int = str.characters.distance(from: str.startIndex, to: range.lowerBound)
            return index
        }
        
        return nil
    }
    
    // MARK: - get core data
    
    func getProjects() -> [Project] {
        
        if let managedObjectContext = managedObjectContext {
            let fetch: NSFetchRequest<Project> = NSFetchRequest(entityName: "Project")
            if detailItem.project == nil {
                fetch.predicate = NSPredicate(format: "open == YES")
            } else {
                fetch.predicate = NSPredicate(format: "open == YES OR self == %@", detailItem.project!)
            }
            let sort = NSSortDescriptor(key: "orderIndex", ascending: true)
            fetch.sortDescriptors = [sort]
            
            do {
                let projects = try managedObjectContext.fetch(fetch)
                return projects
                
            } catch {
                print("Fetch projects failed")
                return []
            }
        }
        
        return []
    }
    
    func changeAccount() {
        if accounts.count != 0 {
            if account == nil {
                account = accounts.first!
            }
            else {
                let i = accounts.index(of: account!)!
                if i == accounts.count - 1 {
                    account = accounts.first!
                }
                else {
                    account = accounts[i + 1]
                }
            }
        }
    }
    
    func changeCurrency() {
        if currencies.count != 0 {
            if currency == nil {
                currency = currencies.first!
            }
            else {
                let i = currencies.index(of: currency!)!
                if i == currencies.count - 1 {
                    currency = currencies.first!
                }
                else {
                    currency = currencies[i + 1]
                }
            }
        }
    }
    
    // MARK: - MOC
    
    var managedObjectContext: NSManagedObjectContext!
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromSumToCategory" {
            let controller = segue.destination as! CategoryTableViewController
            
            fillDetail()
            
            controller.detailItem = detailItem
        } else if segue.identifier == "fromSumToDetail" {
            let controller = segue.destination as! TransactionDetailViewController
            
            fillDetail()
            
            controller.detailItem = detailItem
        }
    }


}
