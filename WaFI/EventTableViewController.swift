//
//  EventTableViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import os.log

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class EventTableViewController: UITableViewController {
    
    //MARK: Properties
    var events = [Event]()
    var currentUser:User = Auth.auth().currentUser!
    let ref: DatabaseReference! = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show edit button
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Load any saved events if available or load example events
        loadFromDB()
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //----------------------------------------------------------------
    
    
    
    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return events.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "EventTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EventTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        // Fetches the appropriate meal for the data source layout.
        let event = events[indexPath.row]
        //create date formatter for date conversion into string
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd"
		let timeformatter = DateFormatter()
		timeformatter.dateFormat = "HH:mm:ss"
        //set values in cells
        cell.eventName.text = event.name
        cell.eventImage.image = event.photo
        cell.eventDetail.text = dateformatter.string(from: event.date) + "\n" + timeformatter.string(from: event.date)
		print(dateformatter.string(from: event.date) + "\n" + timeformatter.string(from: event.date))
        return cell
    }
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
			print(indexPath.row)
            events.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
			saveEventsToDatabase()
			print("removing from firebase node \(events.count+1)")
			self.ref.child("users").child(currentUser.uid).child("\(events.count+1)").removeValue()
        } else if editingStyle == .insert {
			saveEventsToDatabase()
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let movedObject = self.events[sourceIndexPath.row]
		events.remove(at: sourceIndexPath.row)
		events.insert(movedObject, at: destinationIndexPath.row)
		NSLog("%@", "\(sourceIndexPath.row) => \(destinationIndexPath.row) \(events)")
		// To check for correctness enable: self.tableView.reloadData()
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
	//function to log out of authenticted user
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
			print(events[index].name)
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
        let imageRef = thisRef.child("\(currentUser.uid)_\(thisEvent.UID)_image.png")
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
            let reference = storageRef.child("\(self.currentUser.uid)_\(temp[i].UID)_image.png")
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
