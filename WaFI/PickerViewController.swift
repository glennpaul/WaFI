//
//  PickerViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import os.log

protocol PickerViewControllerDelegate: class {
    func dateTimeChosen(thisEvent:Event?)
}

class PickerViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    weak var delegate: PickerViewControllerDelegate?
    var event: Event?
    var time:String! = "4:20 AM"
    var date:String! = "03/14/95"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //create date time formatters and set date time variables
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        time = timeFormatter.string(from: timePicker.date)
        date = dateFormatter.string(from: datePicker.date)
        
        dateTimeLabel.font = dateTimeLabel.font.withSize(30)
        dateTimeLabel.text = timeFormatter.string(from: timePicker.date) + " on " + dateFormatter.string(from: Date())
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //----------------------------------------------------------------
    
    
    //MARK: Actions
    @IBAction func changeTime(_ sender: Any, forEvent event: UIEvent) {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        time = timeFormatter.string(from: timePicker.date)
        updateLabel()
    }
    @IBAction func changeDate(_ sender: UIDatePicker, forEvent event: UIEvent) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        date = dateFormatter.string(from: datePicker.date)
        updateLabel()
    }
    private func updateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateTimeLabel.text = time + " on " + dateFormatter.string(from: datePicker.date)

        //format string into date for final event and set it
        let strToDate = DateFormatter()
        strToDate.dateFormat = "M/d/yy h:mm a" //format of label
        event?.date = strToDate.date(from: date + " " + time)!
        
        
        //test what it will look like on final page
        //let second = DateFormatter()
        //second.dateFormat = "yyyy-MM-dd HH:mm:ss" //Your date format
        //print(second.string(from: (event?.date)!))
        
    }
    
    
    //----------------------------------------------------------------
    

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func finishEdit(_ sender: UIBarButtonItem) {
        delegate?.dateTimeChosen(thisEvent:event)
        dismiss(animated: true, completion: nil)
    }

}
