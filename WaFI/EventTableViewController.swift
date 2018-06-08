//
//  EventTableViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import os.log

class EventTableViewController: UITableViewController {

    
    //MARK: Properties
    var events = [Event]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show edit button
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        // Load any saved events if available or load example events
        if let savedEvents = loadEvents() {
            events += savedEvents
        } else {
            loadSampleEvents()
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //----------------------------------------------------------------
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return events.count
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
            //save all showed events
            saveEvents()
        }
    }
    
    
    
    
    
    //----------------------------------------------------------------
    
    
    
    
    
    //MARK: Private Methods
    
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
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

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
    
    //MARK: Private functions
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
 

}
