//
//  SelectPeriodViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 11/10/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class SelectPeriodViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var startDatePeriodSC: UISegmentedControl!
    @IBOutlet weak var startDateLable: UILabel!
    @IBOutlet weak var endDateLable: UILabel!
    @IBOutlet weak var periodLable: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var periodPicker: UIPickerView!
    @IBOutlet weak var standartPeriodsSC: UISegmentedControl!
    
    
    var periodPickerData: [[Int]] = [[],[],[]]
    
    var standartPeriod: StandartPeriod?
    var period: [Int]!
    var startDate: Date!
    var endDate: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        self.navigationItem.leftBarButtonItems = [cancelButton]
        
        let saveButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(saveTapped))
        
        self.navigationItem.rightBarButtonItems = [saveButton]
        
        self.periodPicker.dataSource = self
        self.periodPicker.delegate = self
        
        fillPeriodPickerData()
        
        startDatePicker.date = startDate
        startDateChanged()
        
        periodPicker.selectRow(period[0], inComponent: 0, animated: true)
        periodPicker.selectRow(period[1], inComponent: 1, animated: true)
        periodPicker.selectRow(period[2], inComponent: 2, animated: true)
        
        periodChanged()
        
        setEndDate()
        
        adjustViews()
        
        standartPeriodsSC.selectedSegmentIndex = standartPeriod?.rawValue ?? UISegmentedControlNoSegment
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveTapped() {
        performSegue(withIdentifier: "unwindToReportsFromPeriod", sender: nil)
    }
    
    func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func adjustViews() {
        startDatePicker.isHidden = (startDatePeriodSC.selectedSegmentIndex != 0)
        periodPicker.isHidden = (startDatePeriodSC.selectedSegmentIndex != 1)
        
        startDateLable.isHighlighted = (startDatePeriodSC.selectedSegmentIndex == 0)
        periodLable.isHighlighted = (startDatePeriodSC.selectedSegmentIndex == 1)
    }

    @IBAction func startDatePeriodChanged(_ sender: UISegmentedControl) {
        adjustViews()
    }
    
    @IBAction func startDateValueChanged(_ sender: UIDatePicker) {
        standartPeriodsSC.selectedSegmentIndex = UISegmentedControlNoSegment
        standartPeriod = nil
        
        startDateChanged()
        periodChanged()
        setEndDate()
    }
    
    @IBAction func standartPeriodChanged(_ sender: Any) {
        
        standartPeriod = StandartPeriod(rawValue: standartPeriodsSC.selectedSegmentIndex)
        
        if let _standartPeriod = standartPeriod {
            
            let params = StandartPeriod.periodParameters(standartPeriod: _standartPeriod)
            
            period = params.period
            periodPicker.selectRow(period[0], inComponent: 0, animated: true)
            periodPicker.selectRow(period[1], inComponent: 1, animated: true)
            periodPicker.selectRow(period[2], inComponent: 2, animated: true)
            
            startDate = params.startDate
            startDatePicker.date = startDate
            
            startDateChanged()
            periodChanged()
            setEndDate()
        }
    }
    // MARK: - Picker delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return periodPickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return periodPickerData[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        var postfix = ""
        
        switch component {
        case 0:
            postfix = "year"
        case 1:
            postfix = "month"
        case 2:
            postfix = "day"
        default:
            postfix = ""
        }
        
        if periodPickerData[component][row] != 1 {
            postfix += "s"
        }
        
        return "\(periodPickerData[component][row]) \(postfix)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        period[component] = row
        
        standartPeriodsSC.selectedSegmentIndex = UISegmentedControlNoSegment
        standartPeriod = nil
        
        startDateChanged()
        periodChanged()
        setEndDate()
    }
    
    // MARK: - Helpers
    
    func fillPeriodPickerData() {
        
        periodPickerData[0] += 0...9
        periodPickerData[1] += 0...12
        periodPickerData[2] += 0...31
    }
    
    func startDateChanged() {
        
        if standartPeriod == .allTime {
            startDateLable.text = "Begin of time"
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        let strDate = dateFormatter.string(from: startDatePicker.date)
        
        startDateLable.text = strDate
        
        startDate = startDatePicker.date
    }
    
    func periodChanged() {
        
        if standartPeriod == .allTime {
            periodLable.text = "All time"
            return
        }
        
        if period[0] == 0 && period[1] == 0 && period[2] == 0 {
            
            period[2] = 1
            periodPicker.selectRow(1, inComponent: 2, animated: true)
        }
        
        var year = ""
        var month = ""
        var day = ""
        
        if period[0] != 0 {
            year = "\(period[0]) \(period[0] == 1 ? "year" : "years")"
        }
        
        if period[1] != 0 {
            month = " \(period[1]) \(period[1] == 1 ? "month" : "months")"
        }
        
        if period[2] != 0 {
            day = " \(period[2]) \(period[2] == 1 ? "day" : "days")"
        }
        
        periodLable.text = "\(year)\(month)\(day)"
        
        if periodLable.text == "" {
            periodLable.text = "0 years 0 months 0 days"
        }
        
    }
    
    func setEndDate() {
        endDate = startDate
        
        if standartPeriod == .allTime {
            endDateLable.text = "End of time"
            return
        }
        
        if period[0] != 0 {
            if let _endDate = Calendar.current.date(byAdding: .year, value: period[0], to: endDate) {
                endDate = _endDate
            }
        }
        
        if period[1] != 0 {
            if let _endDate = Calendar.current.date(byAdding: .month, value: period[1], to: endDate) {
                endDate = _endDate
            }
        }
        
        if period[2] != 0 {
            if let _endDate = Calendar.current.date(byAdding: .day, value: period[2], to: endDate) {
                endDate = _endDate
            }
        }
        
        endDate = endDate - 1
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        let strDate = dateFormatter.string(from: endDate)
        
        endDateLable.text = strDate

    }
    
    func setStandartPeriodSegmentedControl() {
        
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

enum StandartPeriod: Int {
    case allTime = 0
    case thisYear = 1
    case thisMonth = 2
    case thisWeek = 3
    case thisDay = 4
    
    static func periodParameters(standartPeriod: StandartPeriod) -> (period: [Int], startDate: Date) {
        switch standartPeriod {
        case .thisYear:
            return ([1,0,0], Date().startOfYear())
        case .thisMonth:
            return ([0,1,0], Date().startOfMonth())
        case .thisWeek:
            return ([0,0,7], Date().startOfWeek())
        case .thisDay:
            return ([0,0,1], Calendar.current.startOfDay(for: Date()))
        case .allTime:
            return ([0,0,0], Calendar.current.startOfDay(for: Date()))
        }
    }
}
