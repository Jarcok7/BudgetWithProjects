//
//  CurrencyTableViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 6/22/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit
import CoreData

class CurrenciesTableViewController: UITableViewController, URLSessionDelegate, URLSessionTaskDelegate, CurrenciesTableViewCellDelegate {

    class Currency {
        var code = ""
        var name = ""
        var used = false
        var orderIndex = 10000
        var rate: Float = 0.0
        
        
        init(code: String, name: String, used: Bool) {
            self.code = code
            self.name = name
            self.used = used
        }
    }
    
    var currencies = [Currency]()
    var usedCurrencies = [UsedCurrency]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usedCurrencies = getUsedCurrencies()
        
        let request = NSMutableURLRequest(url: URL(string: "https://openexchangerates.org/api/currencies.json")!)
        
        httpGet(request) { (resultString, error) -> Void in
            self.callback(resultString, error, self)
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
        
        self.navigationItem.title = "Currencies"
        
        self.isEditing = true
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helpers
    
    func saveButtonTapped() {
        saveUsedCurrencies()
        self.performSegue(withIdentifier: "unwindToSettingsFromCurrencies", sender: self)
    }
    
    func saveUsedCurrencies() {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if let managedObjectContext = delegate?.managedObjectContext {
            
            var i = 0
            for currency in currencies {
                
                let filteredUsedCurrencies = usedCurrencies.filter({$0.code == currency.code})
                
                if filteredUsedCurrencies.count == 1 {
                    
                    i = i + 1
                    
                    let usedCurrency = filteredUsedCurrencies.first!
                    
                    usedCurrency.orderIndex = NSNumber(value: i)
                    usedCurrency.used = currency.used
                    
                } else if currency.used {
                    
                    i = i + 1
                    
                    if let usedCurrency = NSEntityDescription.insertNewObject(forEntityName: "UsedCurrency", into: managedObjectContext) as? UsedCurrency {
                        
                        usedCurrency.code = currency.code
                        usedCurrency.name = currency.name
                        usedCurrency.orderIndex = NSNumber(value: i)
                        usedCurrency.used = currency.used
                        usedCurrency.rate = 1
                        usedCurrency.rateDate = Date() - 24 * 3600
                        
                    }
                }
            }
            
            AppDelegate.saveContext(managedObjectContext)
            
            DispatchQueue.global(qos: .background).async {
                UsedCurrency.updateRates(managedObjectContext)
            }
        }
        else {
            print("Can't get managed object context for saving currencies")
        }
    }
    
    func convertStringToDictionary(_ text: String) -> [String:String]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:String]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    func getDictJSONFromResorseFile() -> [String:String]?  {
        return UsedCurrency.getDictJSONFromResorseFile()
    }
    
    func getUsedCurrencies() -> [UsedCurrency] {
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if let managedObjectContext = delegate?.managedObjectContext {
            let fetch: NSFetchRequest<UsedCurrency> = NSFetchRequest(entityName: "UsedCurrency")
            let sort = NSSortDescriptor(key: "orderIndex", ascending: true)
            fetch.sortDescriptors = [sort]
            
            do {
                let usedCurrencies = try managedObjectContext.fetch(fetch)
                return usedCurrencies
                
            } catch {
                print("Fetch used currencies failed")
                return []
            }
        }

        return []
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath) as! CurrencyTableViewCell

        let currency = currencies[(indexPath as NSIndexPath).row]
        cell.name.text = currency.name //String(currency.rate) + "-" + currency.name
        cell.code.text = currency.code
        cell.used.isOn = currency.used
        cell.delegate = self

        return cell
    }

    //MARK - NSURLSessionDelegate
    
    typealias CallbackBlock = (_ result: String, _ error: String?, _ delegate: CurrenciesTableViewController) -> Void
    
    var callback: CallbackBlock = { (resultString, error, delegate) -> Void in
        
        var dictJSON: [String: String]? = nil
        
        if error == nil {
            
            dictJSON = delegate.convertStringToDictionary(resultString)
            
        } else {
            print(error!)
        }
        
        if dictJSON == nil {
            dictJSON = delegate.getDictJSONFromResorseFile()
        }
        
        if dictJSON != nil {
            
            let usedCurrencies = delegate.usedCurrencies
            
            for (code, name) in dictJSON! {
                let newCurrency = Currency(code: code, name: name, used: false)
                
                if let filteredCurrency = usedCurrencies.filter({$0.code == code}).first {
                    newCurrency.used = filteredCurrency.used
                    newCurrency.orderIndex = filteredCurrency.orderIndex.intValue
                    newCurrency.rate = filteredCurrency.rate
                }
                
                delegate.currencies.append(newCurrency)
            }
            
            delegate.currencies.sort(by: {(o1: Currency, o2: Currency) -> Bool in return Int(o1.orderIndex) == Int(o2.orderIndex) ? o1.name < o2.name : Int(o1.orderIndex) < Int(o2.orderIndex)})
            delegate.tableView.reloadData()
            
        }
    }
    
    func httpGet(_ request: NSMutableURLRequest!, callback: @escaping (String,
        String?) -> Void) {
        let configuration =
            URLSessionConfiguration.default
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue:OperationQueue.main)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if let error = error {
                callback("", error.localizedDescription)
            } else {
                let result = String(data: data!, encoding: .ascii)!
                callback(result as String, nil)
            }
        
        })
        
        task.resume()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        //print("did autherntcationchallenge = \(challenge.protectionSpace.authenticationMethod)")
        
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request:
        URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let newRequest : URLRequest? = request
        print(newRequest?.description ?? "");
        completionHandler(newRequest)
    }
    
    // MARK - conform to CurrencyTableViewCellDelegate protocol
    
    func didChangeSwitchState(_ sender: CurrencyTableViewCell, isOn: Bool) {
        
        if currencies.filter({ $0.used }).count == 1 && !isOn {
            
            let alert = UIAlertController(title: nil, message: "Must be at least one used currency", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            sender.used.isOn = true
        } else {
            
            let indexPath = self.tableView.indexPath(for: sender)
            let currency = currencies[(indexPath! as NSIndexPath).row]
            currency.used = isOn
            self.tableView.reloadRows(at: [indexPath!], with: .automatic)
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
        let fromCurrency = currencies[(fromIndexPath as NSIndexPath).row]
        
        currencies.remove(at: (fromIndexPath as NSIndexPath).row)
        currencies.insert(fromCurrency, at: (toIndexPath as NSIndexPath).row)
        
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        let currency = currencies[(indexPath as NSIndexPath).row]
        
        return currency.used
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
