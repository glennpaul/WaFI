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
        print(currentUser.uid)
        ref.child("events_count").child(currentUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            //if snapshot.value as? Int != 0 && snapshot.value != nil {
                print("load events from db")
            
            self.loadEventsFromFirebase()
            //}
        }) { (error) in
            print(error.localizedDescription)
        }
        
        if let savedEvents = loadEvents() {
            events += savedEvents
        } else {
            loadSampleEvents()
        }
        
        //save event names to db
        saveEventsToDatabase()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //----------------------------------------------------------------
    
    
    //MARK: Actions
    
    
    @IBAction func unwindToEventList(sender: UIStoryboardSegue) {
        //make sure coming from viewcontroller scene
        if let sourceViewController = sender.source as? ViewController, let event = sourceViewController.event {
            //make sure to update if editing event, or add new if new event
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                //update event and table
                events[selectedIndexPath.row] = event
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else {
                // Add a new meal.
                let newIndexPath = IndexPath(row: events.count, section: 0)
                //append to event list and insert to table
                events.append(event)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            //save all showed events to phone and db
            saveEvents()
            saveEventsToDatabase()
        }
    }
    @IBAction func logOut(_ sender: UIBarButtonItem) {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "signInPage")
                present(vc, animated: true, completion: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        //set values in cells
        cell.eventName.text = event.name
        cell.eventImage.image = event.photo
        cell.eventDetail.text = formatter.string(from: event.date)
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
            events.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveEvents()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
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
    
    //MARK: Private functions
    private func loadSampleEvents() {
        //load sample photos for sample events
        let photo1 = UIImage(named: "event1")
        let photo2 = UIImage(named: "event2")
        let photo3 = UIImage(named: "event3")
        //create sample events
        guard let event1 = Event(name: "Graduation", photo: photo1, date:Date()) else {
            fatalError("Unable to instantiate event1")
        }
        guard let event2 = Event(name: "Work", photo: photo2, date:Date()) else {
            fatalError("Unable to instantiate event2")
        }
        guard let event3 = Event(name: "Death", photo: photo3, date:Date()) else {
            fatalError("Unable to instantiate event3")
        }
        //add sample events to event list
        events += [event1, event2, event3]
    }
    private func saveEvents() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(events, toFile: Event.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Events successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save events...", log: OSLog.default, type: .error)
        }
    }
    private func loadEvents() -> [Event]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Event.ArchiveURL.path) as? [Event]
    }
    private func loadEventsFromFirebase() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a MMM d, yyyy " //date format
        let defaultPhoto = UIImage(named: "defaultPhoto")
        guard let tempEvent = Event(name: "tempName", photo: defaultPhoto, date:Date()) else {
            fatalError("Unable to instantiate temporary event")
        }
        
        //for index in 1...6 {
        //    print(index)
        //}
        
        
        ref.child("users").child(currentUser.uid).child("1").child("name").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value as? Int != 0 && snapshot.value != nil {
                tempEvent.name = snapshot.value! as! String
                //set image
                let storageRef = Storage.storage().reference()
                let reference = storageRef.child("\(self.currentUser.uid)_\(tempEvent.name)_image.png")
                
                reference.getData(maxSize: 100 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        print(error!)
                    } else {
                        tempEvent.photo = UIImage(data: data!)
                    }
                }
                self.ref.child("users").child(self.currentUser.uid).child("1").child("date").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.value != nil {
                        tempEvent.date = dateFormatter.date(from: snapshot.value as! String)!
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
            self.events.append(tempEvent)
            
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: self.events.count-1, section: 0)], with: .automatic)
            self.tableView.endUpdates()
        }) { (error) in
            print(error.localizedDescription)
        }
    
    }
    
    
    //MARK: Database and Storage Functions
    private func saveEventsToDatabase() {
        for (index,event) in events.enumerated() {
            //print(index)
            
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy" //date format
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a" //time format
            
            
            let thisEvent = [
                "name":event.name,
                "date": timeFormatter.string(from: (event.date))  + " " + dateFormatter.string(from: (event.date))
                ]
            let insertNode = ["\(index + 1)":thisEvent]
            self.ref.child("users").child(currentUser.uid).updateChildValues(insertNode)
            
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            uploadImage(event,storageRef)
        }
    }
    func uploadImage(_ thisEvent:Event,_ thisRef:StorageReference) {
        let data = UIImageJPEGRepresentation(thisEvent.photo!, 1)
        let imageRef = thisRef.child("\(currentUser.uid)_\(thisEvent.name)_image.png")
        _ = imageRef.putData(data!, metadata:nil,completion:{(metadata,error)
            in guard metadata != nil else {
                print(error!)
                return
            }
            //let downloadURL = metadata.path
            //print(downloadURL!)
            
        })
        
    }

}
