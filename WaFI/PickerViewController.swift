//
//  PickerViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import os.log

class PickerViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var time:String! = ""
    var date:String! = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        
        time = timeFormatter.string(from: timePicker.date)
        date = dateFormatter.string(from: datePicker.date)
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func changeTime(_ sender: Any, forEvent event: UIEvent) {
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        
        time = timeFormatter.string(from: timePicker.date)
        updateLabel()
        print(time)
    }
    @IBAction func changeDate(_ sender: UIDatePicker, forEvent event: UIEvent) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        
        date = dateFormatter.string(from: datePicker.date)
        updateLabel()
        print(date)
    }
    
    
    
    private func updateLabel() {
        navigationItem.title = time + " on " + date
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
