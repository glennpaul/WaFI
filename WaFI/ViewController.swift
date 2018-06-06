//
//  ViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-03.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, PickerViewControllerDelegate {
    
    //PickerviewController delegate action
    func dateTimeChosen(thisEvent:Event?) {
        print("doing")
        event = thisEvent
    }
    
    //MARK: Properties
    @IBOutlet weak var editText: UITextField!
    @IBOutlet weak var photo: UIImageView!


    var event: Event?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //make delegate for editText
        editText.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        print(event?.date ?? "hi")
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        navigationItem.title = textField.text
    }
    //MARK: Actions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        //print("got here 1")
        //event = Event(name:navigationItem.title!,photo:photo,date:Date())
        //    print("got here 2")
        print(segue.destination)
        if let navController = segue.destination as? UINavigationController {
            let PickerView = navController.topViewController as! PickerViewController
            let photo = UIImage(named: "defaultPhoto")
            PickerView.event = Event(name:navigationItem.title!,photo:photo,date:Date())
            print("got here 2")
        }
        //print("got here 3")
    }
    
    


}

