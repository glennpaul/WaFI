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
        
        
        let waitline = DispatchGroup()
        waitline.enter()
        
        // avoid deadlocks by not using .main queue here
        DispatchQueue.main.async {
            self.grabEvent { (temp) in
                
                if let temp = temp {
                    self.events = temp
                    print(self.events[0].name)
                    self.tableView.beginUpdates()
                    print(self.events.count)
                    for index in 0..<self.events.count {
                        print()
                        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                    //self.tableView.insertRows(at: [IndexPath(row: self.events.count-1, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                    waitline.leave()
                }
            }
        }
        
        waitline.notify(queue: .main) {
            self.timeGrabPhotos()
        }
        
        
        
        
        
        
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
            //save all showed events to db
            //saveEventsToDatabase()
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
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        //saveEventsToDatabase()
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
   
    //MARK: Database and Storage Functions
    /*
    private func saveEventsToDatabase() {
        for (index,event) in events.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy" //date format
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a" //time format
            
            let thisEvent = [
                "name":events[index].name,
                "date": timeFormatter.string(from: (events[index].date))  + " " + dateFormatter.string(from: (events[index].date))
                ]
            let insertNode = ["\(index+1)":thisEvent]
            self.ref.child("users").child(currentUser.uid).updateChildValues(insertNode)
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            uploadImage(events[index],storageRef)
            print("saved \(events[index].name)")
            self.ref.child("events_count/").setValue(["\(currentUser.uid)":index])
            print("saving index: \(index) with event \(events[index].name)")
        }
    }
    */
    
    //MARK: Completion handlers
    func grabEvent(completion: @escaping ([Event]?) -> Void) {
        
        let ref = Database.database().reference()
        var eventArray = [Event]()
        
        ref.child("users").child(currentUser.uid).observe(.value, with: { (snapshot) in
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? DataSnapshot {
                guard
                    let theEvent = data.value as? Dictionary<String,String>,
                    let eventName = theEvent["name"],
                    let eventDate = theEvent["date"]
                    else {
                        print("Error! - Incomplete Data")
                        completion(nil)
                        return
                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "h:mm a MMM d, yyyy " //date format
                let defaultPhoto = UIImage(named: "defaultPhoto")
                guard let temp = Event(name: "tempName", photo: defaultPhoto, date:Date()) else {
                    fatalError("Unable to instantiate temporary event")
                }
                temp.name = eventName
                temp.date = dateFormatter.date(from: eventDate)!
                
                eventArray.append(temp)
            }
            completion(eventArray)
        })
    }
    
    func timeGrabPhotos() {
        print("timegrabphoto called")
        grabPhoto(self.events[self.events.count-1]) { (photo) in
            print("getphoto finished with event \(self.events[self.events.count-1].name)")
            if let photo = photo {
                for index in 0..<self.events.count {
                    print("setting even photo for event \(self.events[index].name)")
                    self.events[index].photo = photo
                }
                self.tableView.reloadData()
            }
        }
        self.tableView.reloadData()
    }
    func grabPhoto(_ temp:Event, completionImage: @escaping (UIImage?) -> Void) {
        
        
        let secondline = DispatchGroup()
        secondline.enter()
        
        print("getphoto called")
        let storageRef = Storage.storage().reference()
        let defaultPhoto = UIImage(named: "defaultPhoto")
        var photoImage:UIImage = defaultPhoto!
        let reference = storageRef.child("\(self.currentUser.uid)_\(temp.name)_image.png")
        reference.getData(maxSize: 10000000 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                print(error!)
            } else {
                print("image grabbed")
                photoImage = UIImage(data: data!)!
                secondline.leave()
            }
        }
        secondline.notify(queue: .main) {
            print("image passed back and view reloaded")
            completionImage(photoImage)
            self.tableView.reloadData()
        }
        
    }
    

}
