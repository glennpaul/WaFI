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
	
	
	@IBOutlet weak var tableView: UITableView!
	
	var events = [Event]()
	var currentUser:User = Auth.auth().currentUser!
	let ref: DatabaseReference! = Database.database().reference()
	var seconds = 0.0
	

    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self
		// Load any saved events if available or load example events
		loadFromDB()
		
		let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditing)) // create a bat button
		navigationItem.rightBarButtonItem = editButton // assign button
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	//MARK: Tableview
	@objc private func toggleEditing() {
		tableView.setEditing(!tableView.isEditing, animated: true) // Set opposite value of current editing status
		navigationItem.rightBarButtonItem?.title = tableView.isEditing ? "Done" : "Edit" // Set title depending on the editing status
	}
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return events.count
	}
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 90
	}
	
	func tableView(_ tableView: UITableView,_ sourceIndexPath: IndexPath,_ proposedDestinationIndexPath: IndexPath) {
		let movedObject = self.events[sourceIndexPath.row]
		events.remove(at: sourceIndexPath.row)
		events.insert(movedObject, at: proposedDestinationIndexPath.row)
		NSLog("%@", "\(sourceIndexPath.row) => \(proposedDestinationIndexPath.row) \(events)")
		// To check for correctness enable: self.tableView.reloadData()
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Table view cells are reused and should be dequeued using a cell identifier.
		let cellIdentifier = "theCell"
		guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EventTableViewCell  else {
			fatalError("The dequeued cell is not an instance of MealTableViewCell.")
		}
		// Fetches the appropriate meal for the data source layout.
		let row = indexPath.row
		let event = events[row]
		//create date formatter for date conversion into string
		let dateformatter = DateFormatter()
		dateformatter.dateFormat = "yyyy-MM-dd"
			//let timeformatter = DateFormatter()
			//timeformatter.dateFormat = "HH:mm:ss"
		//set values in cells
		cell.eventName?.text = event.name
		cell.eventImage?.image = event.photo
		cell.eventDetail?.text = dateformatter.string(from: event.date) //+ "\n" + timeformatter.string(from: event.date)
		return cell
	}
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	
	// Override to support editing the table view.
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			
			let imageStorage = Storage.storage().reference()
			let reference = imageStorage.child("/event_images/\(self.currentUser.uid)_\(events[indexPath.row].UID)_image.png")
			reference.delete { error in
				if let error = error {
					print(error)
				} else {
					// Delete the row from the data source
					self.events.remove(at: indexPath.row)
					tableView.deleteRows(at: [indexPath], with: .fade)
					self.saveEventsToDatabase()
					self.ref.child("users").child(self.currentUser.uid).child("\(self.events.count+1)").removeValue()
				}
			}
			
			
		} else if editingStyle == .insert {
			saveEventsToDatabase()
			// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
		}
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	// Override to support conditional editing of the table view.
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let movedObject = self.events[sourceIndexPath.row]
		events.remove(at: sourceIndexPath.row)
		events.insert(movedObject, at: destinationIndexPath.row)
		NSLog("%@", "\(sourceIndexPath.row) => \(destinationIndexPath.row) \(events)")
		// To check for correctness enable: self.tableView.reloadData()
	}
	
	
	
	
	//----------------------------------------------------------------
	
	//MARK: Timer functions
	
	@objc func tickTimer(){
		let dateformatter = DateFormatter()
		dateformatter.dateFormat = "yyyy-MM-dd"
		
		for (index,theEvent) in events.enumerated() {
			let cell = self.tableView.cellForRow(at: IndexPath(row:index,section:0)) as! EventTableViewCell
			//cell.eventDetail?.text = dateformatter.string(from: theEvent.date) + "\n" + stringFromTimeInterval(interval: theEvent.date.timeIntervalSince(Date()))
			let timeformatter = DateFormatter()
			timeformatter.dateFormat = "HH:mm:ss"
			var comp = DateComponents()
			comp.day = 1
			if theEvent.date < Calendar.current.date(byAdding: comp, to: Date())! && theEvent.date > Date() {
				cell.countdownLabel.text = stringFromTimeInterval(interval: theEvent.date.timeIntervalSince(Date()))
			} else if (theEvent.date < Calendar.current.date(byAdding: comp, to: Date())! && theEvent.date < Date()) {
				cell.countdownLabel.text = "DONE"
			}
		}
	}
	func startTimer() {
		_ = Timer.scheduledTimer(timeInterval: 0.99, target: self, selector: (#selector(ViewController.tickTimer)), userInfo: nil, repeats: true)
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
	
	// MARK: Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
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
	
	@IBAction func edit(_ sender: UIBarButtonItem) {
		self.isEditing = !self.isEditing
	}
	
	@IBAction func unwindToEventList(sender: UIStoryboardSegue) {
		//make sure coming from viewcontroller scene
		if let sourceViewController = sender.source as? ViewController, let event = sourceViewController.event {
			//make sure to update if editing event, or add new if new event
			if let selectedIndexPath = tableView.indexPathForSelectedRow { //if editing a selected row update event and table
				events[selectedIndexPath.row] = event
				tableView.reloadRows(at: [selectedIndexPath], with: .none)
			} else {
				// Add a new meal.
				let newIndexPath = IndexPath(row: events.count, section: 0) // if adding new event, append to table
				events.append(event)
				tableView.insertRows(at: [newIndexPath], with: .automatic)
			}
			saveEventsToDatabase()
		}
	}
	@IBAction func logOut(_ sender: UIBarButtonItem) {
		if Auth.auth().currentUser != nil {
			do {
				//save events and their data first, then log out and return to sign in page
				saveEventsToDatabase()
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
	
	//function to grab events with their name and date from the firebase database
	private func loadFromDB() {
		let waitline = DispatchGroup()
		waitline.enter()
		DispatchQueue.main.async {
			self.events.removeAll()
			//call function to grab events from database and load them into the table once all grabbed
			self.grabEvent { (temp) in
				if let temp = temp {
					self.events = temp
					self.tableView.beginUpdates()
					for index in 0..<temp.count {
						//insert event rows into table
						self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
					}
					self.startTimer()
					self.tableView.endUpdates()
					waitline.leave()
				}
			}
		}
		waitline.notify(queue: .main) {
			/*once events are all grabbed and table is populated with the events,
			call function to get their photos and update table*/
			self.updateTableWithPhotos()
		}
	}
	private func saveEventsToDatabase() {
		for (index,_) in events.enumerated() {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "MMM d, yyyy" //date format
			let timeFormatter = DateFormatter()
			timeFormatter.dateFormat = "h:mm a" //time format
			let thisEvent = [
				"name":events[index].name,
				"date": timeFormatter.string(from: (events[index].date))  + " " + dateFormatter.string(from: (events[index].date)),
				"UID":events[index].UID
			]
			let insertNode = ["\(index+1)":thisEvent]
			self.ref.child("users").child(currentUser.uid).updateChildValues(insertNode)
			let storage = Storage.storage()
			let storageRef = storage.reference()
			uploadImage(events[index],storageRef)
			let insertCount = ["\(currentUser.uid)":events.count]
			self.ref.child("events_count/").updateChildValues(insertCount)
		}
	}
	func uploadImage(_ thisEvent:Event,_ thisRef:StorageReference) {
		let data = UIImageJPEGRepresentation(thisEvent.photo!, 1)
		let imageRef = thisRef.child("/event_images/\(currentUser.uid)_\(thisEvent.UID)_image.png")
		_ = imageRef.putData(data!, metadata:nil,completion:{(metadata,error)
			in guard let metadata = metadata else {
				print(error!)
				return
			}
			_ = metadata.path
		})
	}
	func grabEvent(completion: @escaping ([Event]?) -> Void) {
		let ref = Database.database().reference()
		var eventArray = [Event]()
		ref.child("users").child(currentUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
			eventArray.removeAll()
			let enumerator = snapshot.children
			while let data = enumerator.nextObject() as? DataSnapshot {
				guard
					let theEvent = data.value as? Dictionary<String,String>,
					let eventName = theEvent["name"],
					let eventDate = theEvent["date"],
					let eventUID = theEvent["UID"]
					else {
						print("Error! - Incomplete Data")
						completion(nil)
						return
				}
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "h:mm a MMM d, yyyy "
				let defaultPhoto = UIImage(named: "defaultPhoto")
				guard let temp = Event(name: "tempName", photo: defaultPhoto, date:Date(),UID:"") else {
					fatalError("Unable to instantiate temporary event")
				}
				temp.name = eventName
				temp.date = dateFormatter.date(from: eventDate)!
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
				}
			}
		}
	}
	func grabPhoto(_ temp:[Event], completionImage: @escaping ([UIImage?]?) -> Void) {
		let storageRef = Storage.storage().reference()
		var thePhotos = [UIImage?](repeating: nil, count: temp.count)
		//setup GCD
		let secondline = DispatchGroup()
		for _ in 0..<temp.count {
			secondline.enter()
		}
		//iterate through events and grab thier images from storage
		for i in 0..<temp.count {
			//grab image name from corresponding event
			let reference = storageRef.child("/event_images/\(self.currentUser.uid)_\(temp[i].UID)_image.png")
			reference.getData(maxSize: 10000000 * 1024 * 1024) { (data, error) -> Void in
				if (error != nil) {
					print(error!)
				} else {
					//insert images to image array in correct order
					thePhotos[i] = UIImage(data: data!)!
					secondline.leave()
				}
			}
		}
		secondline.notify(queue: .main) {
			//pass the images grabbed from firebase storage to function that will update table
			completionImage(thePhotos)
		}
	}
	
	
	

}
