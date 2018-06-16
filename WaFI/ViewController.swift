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
	@IBOutlet weak var timeDiffLabel: UILabel!
	var event: Event?
	var countDown: Timer?
	var seconds = 0.0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        editText.delegate = self
        updateSaveButtonState()
        
        if let event = event {
			
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "MMM d, yyyy" //date format
			let timeFormatter = DateFormatter()
			timeFormatter.dateFormat = "h:mm a" //time format
			let newDate = timeFormatter.string(from:event.date)  + " on " + dateFormatter.string(from: event.date)
			
            navigationItem.title = event.name
            photoImage.image = event.photo
            dateTimeLabel.text = newDate
			
			if dateTimeLabel.text != "Event must have Date/Time" {
				seconds = (event.date.timeIntervalSince(Date()))
				timeDiffLabel.text = stringFromTimeInterval(interval: (event.date.timeIntervalSince(Date())))
			} else {
				timeDiffLabel.text = ""
			}
			
			updateSaveButtonState()
			startTimer()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //----------------------------------------------------------------
	
	//MARK: Timer Functions
	
	@objc func tickTimer(){
		seconds -= 1
		timeDiffLabel.text = stringFromTimeInterval(interval: TimeInterval(seconds))
	}
	func startTimer() {
		countDown = Timer.scheduledTimer(timeInterval: 0.95, target: self, selector: (#selector(ViewController.tickTimer)), userInfo: nil, repeats: true)
	}
	func stringFromTimeInterval(interval: TimeInterval) -> String {
		
		let countdownFormatter = NumberFormatter()
		countdownFormatter.minimumIntegerDigits = 2
		
		let hours = Int(interval) / 3600
		let minutes = Int(interval) / 60 % 60
		let seconds = Int(interval) % 60
		return countdownFormatter.string(from: NSNumber.init(value: hours))! + ":" + countdownFormatter.string(from: NSNumber.init(value: minutes))! + ":" + countdownFormatter.string(from: NSNumber.init(value: seconds))!
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
		if dateTimeLabel.text != "Event must have Date/Time" {
			seconds = (event?.date.timeIntervalSince(Date()))!
			timeDiffLabel.text = stringFromTimeInterval(interval: (event?.date.timeIntervalSince(Date()))!)
		} else {
			timeDiffLabel.text = ""
		}
		startTimer()
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
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // Set photoImageView to display the selected image.
        photoImage.image = resize(selectedImage)
        event?.photo = resize(selectedImage)
        
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
	//enable/disable save button when required
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
	//resize image to save data when uploading/downloading
	private func resize(_ image: UIImage) -> UIImage {
		var actualHeight = Float(image.size.height)
		var actualWidth = Float(image.size.width)
		let maxHeight: Float = 1024.0
		let maxWidth: Float = 1024.0
		var imgRatio: Float = actualWidth / actualHeight
		let maxRatio: Float = maxWidth / maxHeight
		let compressionQuality: Float = 1 //change for better compression
		//50 percent compression
		if actualHeight > maxHeight || actualWidth > maxWidth {
			if imgRatio < maxRatio {
				//adjust width according to maxHeight
				imgRatio = maxHeight / actualHeight
				actualWidth = imgRatio * actualWidth
				actualHeight = maxHeight
			}
			else if imgRatio > maxRatio {
				//adjust height according to maxWidth
				imgRatio = maxWidth / actualWidth
				actualHeight = imgRatio * actualHeight
				actualWidth = maxWidth
			}
			else {
				actualHeight = maxHeight
				actualWidth = maxWidth
			}
		}
		let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(actualWidth), height: CGFloat(actualHeight))
		UIGraphicsBeginImageContext(rect.size)
		image.draw(in: rect)
		let img = UIGraphicsGetImageFromCurrentImageContext()
		let imageData = UIImageJPEGRepresentation(img!, CGFloat(compressionQuality))
		UIGraphicsEndImageContext()
		return UIImage(data: imageData!) ?? UIImage()
	}


}

