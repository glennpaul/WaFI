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
    
    var event: Event?
    weak var delegate: PickerViewControllerDelegate?
    
    //MARK: Properties
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    var time:String! = ""
    var date:String! = ""
    
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
    
    
    
    
    
    
    //MARK: Actions
    @IBAction func changeTime(_ sender: Any, forEvent event: UIEvent) {
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        
        time = timeFormatter.string(from: timePicker.date)
        updateLabel()
    }
    @IBAction func changeDate(_ sender: UIDatePicker, forEvent event: UIEvent) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        
        date = dateFormatter.string(from: datePicker.date)
        updateLabel()
    }
    private func updateLabel() {
        dateTimeLabel.text = time + " on " + date
        
        print(event?.name ?? "NOOO")
        event?.date = timePicker.date
        print(event?.date ?? "0:00")
    }
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func finishEdit(_ sender: UIBarButtonItem) {
        delegate?.dateTimeChosen(thisEvent:event)
        print("finishedit")
        dismiss(animated: true, completion: nil)
    }
    
    

    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
        let string = date + " at " + time
        event = Event(name: (event?.name)!, photo: event?.photo, date: dateFormatter.date(from: string)!)
        
    }
     */

}
