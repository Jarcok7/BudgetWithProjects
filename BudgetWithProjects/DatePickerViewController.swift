//
//  DatePickerViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 9/7/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class DatePickerViewController: UIViewController {

    var timeStamp: Date?
    var detailItem: TempTransaction?
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePiker: UIDatePicker!
    @IBOutlet weak var planWithoutDateButton: UIButton!
    
    var editMode = true
    var repaymentMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Date"
        
        var buttons: [UIBarButtonItem]
        if !editMode {
            buttons = [UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextTapped))]
        } else {
            buttons = [UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveDate))]
        }
        
        self.navigationItem.rightBarButtonItems = buttons

        if let _date = timeStamp {
            datePiker.date = _date
        }
        
        onDateChanged()
        
        planWithoutDateButton.isHidden = !(repaymentMode || (detailItem?.plan ?? false))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        
        onDateChanged()
    }
    
    @IBAction func todayTapped(_ sender: UIButton) {
        datePiker.date = Calendar.current.startOfDay(for: Date())
        onDateChanged()
    }
    
    @IBAction func planWithoutDateTapped(_ sender: UIButton) {
        if repaymentMode {
            detailItem?.repaymentDate = nil
        } else {
            detailItem?.timeStamp = nil
        }
        
        if editMode {
            self.performSegue(withIdentifier: "unwindToDetailsFromDatePicker", sender: self)
        } else {
            self.performSegue(withIdentifier: "fromDatePickerToDetail", sender: self)
        }
    }
    
    func onDateChanged() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        let strDate = dateFormatter.string(from: datePiker.date)
        dateLabel.text = strDate
    }
    
    func saveDate() {
        timeStamp = datePiker.date
        if let timeStamp = timeStamp {
            if repaymentMode {
                detailItem?.repaymentDate = Calendar.current.startOfDay(for: timeStamp)
            } else {
                detailItem?.timeStamp = Calendar.current.startOfDay(for: timeStamp)
            }
            
        }
        
        self.performSegue(withIdentifier: "unwindToDetailsFromDatePicker", sender: self)
    }
    
    func nextTapped() {
        timeStamp = datePiker.date
        detailItem?.repaymentDate = timeStamp
        self.performSegue(withIdentifier: "fromDatePickerToDetail", sender: self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "fromDatePickerToDetail" {
            let controller = segue.destination as! TransactionDetailViewController
            controller.detailItem = detailItem
        }
    }

}
