//
//  EventTableViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit

class EventTableViewController: UITableViewController {

    
    //MARK: Properties
    var events = [Event]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the three sample events
        loadSampleEvents()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return events.count
    }
    
    //MARK: Actions
    @IBAction func unwindToEventList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ViewController, let event = sourceViewController.event {
            
            // Add a new meal.
            let newIndexPath = IndexPath(row: events.count, section: 0)
            
            events.append(event)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
    
    
    //MARK: Private Methods
    
    private func loadSampleEvents() {
        
        let photo1 = UIImage(named: "event1")
        let photo2 = UIImage(named: "event2")
        let photo3 = UIImage(named: "event3")
        
        guard let event1 = Event(name: "Graduation", photo: photo1, date:Date()) else {
            fatalError("Unable to instantiate event1")
        }
        
        guard let event2 = Event(name: "Work", photo: photo2, date:Date()) else {
            fatalError("Unable to instantiate event2")
        }
        
        guard let event3 = Event(name: "Death", photo: photo3, date:Date()) else {
            fatalError("Unable to instantiate event3")
        }
        
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
        // initially set the format based on your datepicker date / server String (change depending on date pickers)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        //set values in cells
        cell.eventName.text = event.name
        cell.eventImage.image = event.photo
        cell.eventDetail.text = formatter.string(from: event.date)
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
