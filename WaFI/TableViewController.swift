//
//  TableViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-12.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//


import UIKit
import os.log

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	//setup firebase user and references
	let currentUser:User = Auth.auth().currentUser!
	let ref: DatabaseReference! = Database.database().reference()
	let firebaseStorage = Storage.storage().reference()
	
	//setup default photo and date-string formatters
	let defaultPhoto = UIImage(named: "defaultPhoto")
	let medDashFormatter = DateFormatter()
	let full = DateFormatter()
	let medMonthFormatter = DateFormatter()
	let timeFormatter = DateFormatter()
	
	//setup lazy loading variables
	let refreshThreshold = 5
	var minload = 1 //start of event grab number
	var maxload = 20 //end of event grab number
	var grabbingEvents = false //boolean to prevent simultaneous event grabs from firebase
	
	//setup data source array and reload table if new events
	var events = [Event]() {
		didSet {
			tableView.reloadData()
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//setup delegate and datasource for UITableView
		tableView.delegate = self
		tableView.dataSource = self
		
		//setup edit button
		let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditing)) // create a bat button
		navigationItem.rightBarButtonItem = editButton // assign button
		
		//setup date-string formatters
		medDashFormatter.dateFormat = "yyyy-MM-dd"
		full.dateFormat = "h:mm a MMM d, yyyy "
		medMonthFormatter.dateFormat = "MMM d, yyyy" //date format
		timeFormatter.dateFormat = "h:mm a" //time format
		
		
		// Load any saved events if available
		getEventsFromFirebase(withCompletion: nil)
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Tableview
	
	//turning editing on and off
	@objc private func toggleEditing() {
		tableView.setEditing(!tableView.isEditing, animated: true) // Set opposite value of current editing status
		navigationItem.rightBarButtonItem?.title = tableView.isEditing ? "Done" : "Edit" // Set title depending on the editing status
		//save only after signaling done editing
		if !tableView.isEditing {
			saveEventsToDatabase()
		}
	}
	//set sections in table
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	//gives number of rows in a section
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return events.count
	}
	//sets height of cells
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 90
	}
	//functionality for moving cell
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		//re-arrange start and end rows depending on if start was later than end
		var start = sourceIndexPath.row
		var end = destinationIndexPath.row
		if start > end {
			start = destinationIndexPath.row
			end = sourceIndexPath.row
		}
		//move event
		let movedObject = self.events[sourceIndexPath.row]
		events.remove(at: sourceIndexPath.row)
		events.insert(movedObject, at: destinationIndexPath.row)
		//iterate through rows of modified position and set modified to true
		for i in start...end {
			events[i].modified = true
		}
	}
	//setup of cell from data source
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Table view cells are reused and should be dequeued using a cell identifier.
		let cellIdentifier = "theCell"
		guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EventTableViewCell  else {
			fatalError("The dequeued cell is not an instance of MealTableViewCell.")
		}
		// Fetches the appropriate meal for the data source layout.
		let row = indexPath.row
		let event = events[row]
		//set values in cells
		cell.eventName?.text = event.name
		cell.eventImage?.image = event.photo
		cell.eventDetail?.text = medDashFormatter.string(from: event.date)
		cell.date = event.date
		//start timer
		cell.shouldSet = 1
		//add cell to table
		return cell
	}
	//set rearranging cells
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	// Override to support editing the table view.
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			//delete image from firebase when deleting event
			let reference = firebaseStorage.child("/event_images/\(self.currentUser.uid)_\(events[indexPath.row].UID)_image.png")
			reference.delete { error in
				if let error = error {
					print(error)
				} else {
					// Delete the row from the data source
					self.events.remove(at: indexPath.row)
					tableView.deleteRows(at: [indexPath], with: .fade)
					for i in (indexPath.row)..<self.events.count {
						//make sure all of the events after are saved since position change
						self.events[i].modified = true
					}
					self.saveEventsToDatabase()
					//make sure event at end of list in firebase is deleted so it isn't duplicated
					self.ref.child("users").child(self.currentUser.uid).child("\(self.events.count+1)").removeValue()
				}
			}
		}
	}
	//prevent indentation
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	// Override to support conditional editing of the table view.
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}
	//function to setup when about to load cell
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		//grab event count first from database
		if (self.events.count - indexPath.row) == self.refreshThreshold && !self.grabbingEvents {
			grabUserEventCount(){ (count) in
				//if almost to end of list, not busy grabbing events or photos and theres more events to grab, then incerement loading function and grab events
				if self.maxload <= count {
					self.minload = self.maxload + 1
					self.maxload += 10
					self.getEventsFromFirebase()
				}
			}
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	// MARK: Navigation
	
	//prepare seque into adding ne wmeal or editing meal
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		switch(segue.identifier ?? "") {
		case "addEvent":
			os_log("Adding a new meal.", log: OSLog.default, type: .debug)
		case "showEvent":
			guard let ViewController = segue.destination as? ViewController else {
				fatalError("Unexpected destination: \(segue.destination)")
			}
			guard let selectedEventCell = sender as? EventTableViewCell else {
				fatalError("Unexpected sender: \(String(describing: sender))")
			}
			guard let indexPath = tableView.indexPath(for: selectedEventCell) else {
				fatalError("The selected cell is not being displayed by the table")
			}
			let selectedEvent = events[indexPath.row]
			ViewController.event = selectedEvent
		default:
			fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Actions
	
	//setup once back from adding meal or editing meal
	@IBAction func unwindToEventList(sender: UIStoryboardSegue) {
		//make sure coming from viewcontroller scene
		if let sourceViewController = sender.source as? ViewController, let event = sourceViewController.event {
			//make sure to update if editing event, or add new if new event
			if let selectedIndexPath = tableView.indexPathForSelectedRow {
				//if editing a selected row update event and table
				events[selectedIndexPath.row] = event
			} else {
				// Add a new meal to end of table
				events.append(event)
			}
			//make sure to save changes
			saveEventsToDatabase()
		}
	}
	//functionality for logging out
	@IBAction func logOut(_ sender: UIBarButtonItem) {
		if Auth.auth().currentUser != nil {
			do {
				//log out and return to sign in page
				try Auth.auth().signOut()
				let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "signInPage")
				present(vc, animated: true, completion: nil)
			} catch let error as NSError {
				print(error.localizedDescription)
			}
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Database and Storage Functions
	
	
	func getEventsFromFirebase(withCompletion completion: (() -> ())? = nil)  {
		//set indicator to grabbing events as true and get the data from data source in background thread
		self.grabbingEvents = true
		DispatchQueue.global(qos: DispatchQoS.background.qosClass).async() { () -> Void in
			self.grabEvent { (temp) in
				if let temp = temp {
					for index in 0..<temp.count {
						//add grabbed events to event array data source
						self.events.append(temp[index])
					}
					//grab photos once array has events
					//self.updateTableWithPhotos()
					self.grabbingEvents = false
				}
			}
		}
	}
	//function for grabbing events from firebase
	func grabEvent(completion: @escaping ([Event]?) -> Void) {
		//setup reference and array to be used
		let ref = Database.database().reference()
		var eventArray = [Event]()
		//setup formatters and default image
		let defaultPhoto = UIImage(named: "defaultPhoto")
		//grab children event of user and insert to array (only set amount from minload to maxload)
		ref.child("users").child(currentUser.uid).queryOrdered(byChild: "number").queryStarting(atValue: minload).queryEnding(atValue: maxload).observeSingleEvent(of: .value, with: { (snapshot) in
			//make sure array to be passed is empty first
			eventArray.removeAll()
			let enumerator = snapshot.children
			while let data = enumerator.nextObject() as? DataSnapshot {
				guard
					//grab data
					let theEvent = data.value as? Dictionary<String,Any>,
					let eventName = theEvent["name"] as! String?,
					let eventDate = theEvent["date"] as! String?,
					let _ = theEvent["number"] as! Int?,
					let eventUID = theEvent["UID"] as! String?
					else {
						//called if data is not correct
						print("Error! - Incomplete Data")
						completion(nil)
						return
				}
				//setup barebones event and populate with grabbed data
				guard let temp = Event(name: "tempName", photo: defaultPhoto, date:Date(),UID:"") else {
					fatalError("Unable to instantiate temporary event")
				}
				temp.name = eventName
				temp.date = self.full.date(from: eventDate)!
				temp.UID = eventUID
				eventArray.append(temp)
			}
			completion(eventArray)
		})
	}
	func updateTableWithPhotos() {
		grabPhoto(self.events) { (photo) in
			if let photo = photo {
				for index in 0..<self.events.count {
					//update image in table row to corresponding event
					self.events[index].photo = photo[index]
					self.tableView.reloadData()
					self.grabbingEvents = false
				}
			}
		}
	}
	//function for grabbing individual photos
	func grabPhoto(_ temp:[Event], completionImage: @escaping ([UIImage?]?) -> Void) {
		//setup reference and array to be used
		var thePhotos = [UIImage?](repeating: nil, count: temp.count)
		//setup GCD
		let wait = DispatchGroup()
		for _ in 0..<temp.count {
			wait.enter()
		}
		//iterate through events and grab thier images from storage
		for i in 0..<temp.count {
			//grab image name from corresponding event
			print("event_images/\(self.currentUser.uid)_\(temp[i].UID)_image.png")
			let reference = firebaseStorage.child("event_images/\(self.currentUser.uid)_\(temp[i].UID)_image.png")
			reference.getData(maxSize: 2 * 1024 * 1024) { (data, error) -> Void in
				if (error != nil) {
					print(error!)
				} else {
					//insert images to image array in correct order
					thePhotos[i] = UIImage(data: data!)!
					wait.leave()
				}
			}
		}
		wait.notify(queue: .main) {
			//pass the images grabbed from firebase storage to function that will update table
			completionImage(thePhotos)
		}
	}
	//save events in table to firebase
	private func saveEventsToDatabase() {
		
		//setup time to string formatters
		
		//setup and save each event
		for (index,_) in events.enumerated() {
			if events[index].modified == true {
				//setup node
				let thisEvent = [
					"name":events[index].name,
					"date": timeFormatter.string(from: (events[index].date))  + " " + medMonthFormatter.string(from: (events[index].date)),
					"UID":events[index].UID,
					"number":index+1
					] as [String : Any]
				let insertNode = ["\(index+1)":thisEvent]
				//save node
				self.ref.child("users").child(currentUser.uid).updateChildValues(insertNode)
				//save photo to storage
				//uploadImage(events[index],firebaseStorage)
				//after saving, reset modified boolean to false
				events[index].modified = false
			}
		}
	}
	//function for uploading single image to firebase storage
	func uploadImage(_ thisEvent:Event,_ thisRef:StorageReference) {
		let data = UIImageJPEGRepresentation(thisEvent.photo!, 1)
		let imageRef = thisRef.child("/event_images/\(currentUser.uid)_\(thisEvent.UID)_image.png")
		_ = imageRef.putData(data!, metadata:nil,completion:{(metadata,error)
			in guard metadata != nil else {
				//for debugging errors
				print(error!)
				return
			}
		})
	}
	//function for grabbing event count
	func grabUserEventCount(completion: @escaping (Int) -> Void) {
		//setup reference to be used
		let ref = Database.database().reference()
		//grab event count and pass to function to load more
		ref.child("events_count").child(currentUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
			let count = (snapshot.value as? Int)!
			completion(count)
		})
	}
	
	
	
	
	
	
	
	
	
	
}
