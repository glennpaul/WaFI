//
//  ViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-03.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import os.log


class ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PickerViewControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var editText: UITextField!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var dateTimeLabel: UILabel!
    var event: Event?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        editText.delegate = self
        updateSaveButtonState()
        
        if let event = event {
            navigationItem.title = event.name
            photoImage.image = event.photo
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy" //date format
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a" //time format
            let newDate = timeFormatter.string(from:event.date)  + " on " + dateFormatter.string(from: event.date) //pass Date here
            
            dateTimeLabel.text = newDate
            updateSaveButtonState()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //----------------------------------------------------------------
    
    
    //MARK: PickerviewControllerDelegate
    func dateTimeChosen(thisEvent:Event?) {
        event = thisEvent
        
        //format string for label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy" //date format
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a" //time format
        let newDate = timeFormatter.string(from: (event?.date)!)  + " on " + dateFormatter.string(from: (event?.date)!) //pass Date here
        
        dateTimeLabel.text = newDate
        updateSaveButtonState()
    }
    
    
    
    //----------------------------------------------------------------
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
        event?.name = textField.text!
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }
    
    
    //----------------------------------------------------------------
    
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // Set photoImageView to display the selected image.
        photoImage.image = selectedImage
        event?.photo = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    
    //----------------------------------------------------------------
    
    
    //MARK: Actions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        if isPresentingInAddMealMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        print(segue.destination)
        if let navController = segue.destination as? UINavigationController {
            let PickerView = navController.topViewController as! PickerViewController
			PickerView.event = Event(name:navigationItem.title!,photo:photoImage.image,date:Date(),UID:randomAlphaNumericString(length:24))
            PickerView.delegate = self
        }
    }
    @IBAction func selectImage(_ sender: UITapGestureRecognizer) {
        // Hide the keyboard.
        editText.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
	
	//function to generate random string
	func randomAlphaNumericString(length: Int) -> String {
		let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		let allowedCharsCount = UInt32(allowedChars.count)
		var randomString = ""
		for _ in 0..<length {
			let randomNum = Int(arc4random_uniform(allowedCharsCount))
			let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
			let newCharacter = allowedChars[randomIndex]
			randomString += String(newCharacter)
		}
		return randomString
	}
    
    //----------------------------------------------------------------
    
    
    //MARK: Private Methods
    private func updateSaveButtonState() {
        //check if creating or modifying event
        let tempName = navigationItem.title
        let tempDate = dateTimeLabel.text
        if tempName != "Event" { //if modifying, enable save without new name, else disable
            saveButton.isEnabled = true
        } else {
            let text = editText.text ?? ""
            saveButton.isEnabled = !text.isEmpty
        }
        if tempDate == "Event must have Date/Time" {
            saveButton.isEnabled = false
        }
    }
    
    


}

