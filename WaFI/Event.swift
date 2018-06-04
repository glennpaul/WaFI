//
//  Event.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit

class Event {
    
    //MARK: Properties
    var name: String
    var photo: UIImage?
    var date: Date
    
    
    init?(name: String, photo: UIImage?, date: Date) {
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty  {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.date = date
        
    }
    
}
