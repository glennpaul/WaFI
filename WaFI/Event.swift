//
//  Event.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import os.log

class Event {
    
    //MARK: Properties
    var name: String
    var photo: UIImage?
    var date: Date
	var UID: String
    
    struct PropertyKey {
        static let name = "name"
        static let photo = "photo"
        static let date = "date"
    }
    
	init?(name: String, photo: UIImage?, date: Date, UID:String) {
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty  {
            return nil
        }
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.date = date
		self.UID = UID
    }
    
}
