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

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	//setup outlet for table
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
			//reload tableview whenever data added
			tableView.reloadData()
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//make sure seperator has no inset
		tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
		
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
		// Set opposite value of current editing status
		tableView.setEditing(!tableView.isEditing, animated: true)
		// Set title depending on the editing status
		navigationItem.rightBarButtonItem?.title = tableView.isEditing ? "Done" : "Edit"
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
			(tableView.cellForRow(at: NSIndexPath(row: i, section: 0) as IndexPath) as! EventTableViewCell).eventUID = events[i].UID
			events[i].modified = true
		}
	}
	//setup of cell from data source
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Table view cells are reused and should be dequeued using a cell identifier.
		let cellIdentifier = "theCell"
		guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EventTableViewCell  else {
			fatalError("The dequeued cell is not an instance of EventTableViewCell.")
		}
		// Fetches the appropriate event for the data source layout.
		let row = indexPath.row
		
		//set event UID for cell, triggers image grab
		cell.UID = currentUser.uid as String
		
		//initialize event values
		let theName = events[row].name
		let thePhoto = events[row].photo
		let theDate = events[row].date
		let theUID = events[row].UID
		
		//set other values in cells
		cell.eventName?.text = theName
		cell.eventImage?.image = thePhoto
		cell.eventDetail?.text = medDashFormatter.string(from: theDate)
		cell.date = theDate
		cell.UID = currentUser.uid
		cell.eventUID = theUID
		
		//start timer and return cell
		cell.shouldSet = 1
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
			print("/event_images/\(self.currentUser.uid)/\(self.currentUser.uid)_\(events[indexPath.row].UID)_image.png")
			let reference = firebaseStorage.child("/event_images/\(self.currentUser.uid)/\(self.currentUser.uid)_\(events[indexPath.row].UID)_image.png")
			reference.delete { error in
				if let error = error {
					print(error)
				} else {
					print("delete successful")
				}
			}
			
			//remove event at end of list so it isn't duplicated when loaded again
			self.ref.child("users").child(self.currentUser.uid).child("\(self.events.count)").removeValue()
			
			// Delete the row from the data source
			self.events.remove(at: indexPath.row)
			
			//make sure the new event numbers are saved in order
			for i in (indexPath.row)..<self.events.count {
				self.events[i].modified = true
			}
			
			//make sure events are saved in case user closes out before pressing editing done button
			self.saveEventsToDatabase()
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
				if self.maxload < count {
					self.minload = self.maxload + 1
					self.maxload += 10
					self.getEventsFromFirebase()
				}
			}
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	// MARK: Navigation
	
	//prepare seque into adding new event or editing event
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		switch(segue.identifier ?? "") {
		case "addEvent":
			os_log("Adding a new event.", log: OSLog.default, type: .debug)
			//deselect
			if let selected = self.tableView.indexPathForSelectedRow{
				self.tableView.deselectRow(at: selected, animated: true)
			}
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
			//make sure photo is passed when about to edit event
			let selectedEvent = events[indexPath.row]
			let cell = tableView.cellForRow(at: indexPath) as! EventTableViewCell
			let thePhoto = cell.eventImage.image
			selectedEvent.photo = thePhoto
			ViewController.event = selectedEvent
		default:
			fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Actions
	
	//setup once back from adding event or editing event
	@IBAction func unwindToEventList(sender: UIStoryboardSegue) {
		
		//make sure coming from viewcontroller scene
		if let sourceViewController = sender.source as? ViewController, let event = sourceViewController.event {
			
			//set modified = true for event in question
			event.modified = true
			
			//make sure to update if editing event, or add new if new event
			if let selectedIndexPath = tableView.indexPathForSelectedRow {
				
				//set event as edited for saving
				let theCell = tableView.cellForRow(at: selectedIndexPath) as! EventTableViewCell
				let cachedImage = theCell.imageCache.object(forKey: event.UID as NSString)
				if cachedImage != event.photo {
					theCell.didChangeImage = true
				}
				
				//initialize event
				let theEvent = event
				
				//set event and event UID for cell and source to trigger image loading
				events[selectedIndexPath.row] = theEvent
				theCell.myEvent = theEvent
				theCell.UID = currentUser.uid
			} else {
				
				// Add a new event to end of table
				let theEvent = event
				events.append(theEvent)
			}
			
			//make sure to save changes
			saveEventsToDatabase()
			
			//deselect
			if let selected = self.tableView.indexPathForSelectedRow{
				self.tableView.deselectRow(at: selected, animated: true)
			}
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
			//save events to firebase
			saveEventsToDatabase()
		}
	}
	//sort events by date
	@IBAction func sortByDate(_ sender: Any) {
		events.sort {
			$0.date < $1.date
		}
		setAllModified()
	}
	//sort events by name
	@IBAction func sortByName(_ sender: UIBarButtonItem) {
		events.sort {
			$0.name < $1.name
		}
		setAllModified()
	}
	//reverse the order of the events
	@IBAction func reverseEvents(_ sender: UIBarButtonItem) {
		events.reverse()
		setAllModified()
	}
	//allow for saving all events easily
	func setAllModified() {
		for (_,event) in events.enumerated() {
			event.modified = true
		}
	}
	
	
	
	
	
	
	
	
	
	
	//----------------------------------------------------------------
	//MARK: Database and Storage Functions
	
	func getEventsFromFirebase(withCompletion completion: (() -> ())? = nil)  {
		//set indicator to grabbing events as true and get the data from data source in background thread
		self.grabbingEvents = true
		
		//grab events in background queue
		DispatchQueue.global(qos: DispatchQoS.background.qosClass).async() { () -> Void in
			self.grabEvent { (temp) in
				if let temp = temp {
					
					//set events in data source and trigger image grab
					for index in 0..<temp.count {
						//add grabbed events to event array data source
						self.events.append(temp[index])
					}
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
		
		//grab children event of user and insert to array (only set amount from minload to maxload)
		ref.child("users").child(currentUser.uid).queryOrdered(byChild: "number").queryStarting(atValue: minload).queryEnding(atValue: maxload).observeSingleEvent(of: .value, with: { (snapshot) in
			
			//make sure array to be passed is empty first
			eventArray.removeAll()
			
			//for each grabbed child node, set object in array with values
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
				guard let temp = Event(name: "tempName", photo: self.defaultPhoto, date:Date(),UID:"") else {
					fatalError("Unable to instantiate temporary event")
				}
				temp.name = eventName
				temp.date = self.full.date(from: eventDate)!
				temp.UID = eventUID
				eventArray.append(temp)
			}
			//pass back
			completion(eventArray)
		})
	}
	//save events in table to firebase
	private func saveEventsToDatabase() {
		
		//setup and save each event
		for (index,_) in events.enumerated() {
			
			//make sure not saving unneccessarily by checking if modified
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
				uploadImage(index,firebaseStorage)
				
				//after saving, reset modified boolean to false
				events[index].modified = false
			}
		}
		
		//update event count for that user in firebase
		let newCount = ["\(currentUser.uid)":events.count]
		self.ref.child("events_count").updateChildValues(newCount)
	}
	//function for uploading single image to firebase storage
	func uploadImage(_ index:Int,_ thisRef:StorageReference) {
		
		//make sure image is loaded
		let Photo = events[index].photo
		let theUID = events[index].UID
		
		//upload to firebase
		let data = UIImageJPEGRepresentation(Photo!, 1)
		let imageRef = thisRef.child("/event_images/\(currentUser.uid)/\(currentUser.uid)_\(theUID)_image.png")
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
		
		//grab event count and pass back to function to load more
		ref.child("events_count").child(currentUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
			let count = (snapshot.value as? Int)!
			completion(count)
		})
	}
	
	
	
	
	
	
	
	
	
	
}
