//
//  EventTableViewCell.swift
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


class EventTableViewCell: UITableViewCell {
    
    //MARK: Properties
	@IBOutlet weak var eventImage: UIImageView!
	@IBOutlet weak var eventName: UILabel!
	@IBOutlet weak var eventDetail: UILabel!
	@IBOutlet weak var countdownLabel: UILabel!
	
	//reference for storage
	let firebaseStorage = Storage.storage().reference()
	
	//image cache so that table doesn't keep downloading image whenever refreshed/cell dequeued
	let imageCache = NSCache<NSString, UIImage>()
	
	//variables for timer setup
	private var timer: Timer?
	private var timeCounter: Double = 0
	var date:Date = Date()
	
	//variables for loading event info per cell
	var myEvent:Event?
	var UID:String = ""
	var eventUID: String = "" {
		willSet {
			
			//create reference to image
			let theUID = newValue
			
			//check if image has changed via edit event
			if didChangeImage == false {
				
				//if not changed check if image is already in cache
				if let cachedImage = imageCache.object(forKey: theUID as NSString) {
					
					//if in cache, grab image from cache
					print("grabbed from cache \(theUID)")
					self.eventImage.image = cachedImage
					myEvent?.photo = cachedImage
					
				} else {
					
					//if not in cache, grab reference to image and grab image
					let reference = firebaseStorage.child("event_images/\(UID)/\(UID)_\(theUID)_image.png")
					reference.getData(maxSize: 2 * 1024 * 1024) { (data, error) -> Void in
						if (error != nil) {
							print(error!)
						} else {
							//once image grabbed from firebase, cache it and set image in cell and event
							print("grabbed from firebase \(theUID)")
							let toBeCached = UIImage(data: data!)!
							self.imageCache.setObject(toBeCached, forKey: theUID as NSString)
							self.eventImage.image = toBeCached
							self.myEvent?.photo = toBeCached
						}
					}
				}
				
			} else {
				
				//if image has changed, set cell image as the new event photo from event and set change back to false once completed
				let thePhoto = myEvent?.photo
				self.imageCache.setObject(thePhoto!, forKey: theUID as NSString)
				eventImage.image = thePhoto
				didChangeImage = false
			}
			
		}
	}
	
	//variable for if time interval should start
	var shouldSet: TimeInterval? {
		//start timer when shouldSet indicator set
		didSet {
			startTimer()
		}
	}
	//indicator if image has changed due to changing it in event edit
	var didChangeImage:Bool? = false {
		didSet {
			if didChangeImage == true {
				//if indicator set, make sure to clear cache for that UID event
				imageCache.removeObject(forKey: eventUID as NSString)
			}
		}
	}
	
	
	
	
	//start timer in cell
	private func startTimer() {
		//setup timer to fire once per second
		if let interval = shouldSet {
			timeCounter = interval
			timer = Timer(timeInterval: 1.0,
						  repeats: true,
						  block: { [weak self] _ in
							guard let strongSelf = self else {
								return
							}
							strongSelf.onComplete()
			})
		}
		RunLoop.current.add(timer!, forMode: .commonModes)
	}
	//function to update labels when timer fires
	@objc func onComplete() {
		
		//initialize date component for adding day
		var comp = DateComponents()
		comp.day = 1
		
		//remove countdown when not needed
		guard timeCounter > 0 else {
			timer?.invalidate()
			timer = nil
			return
		}
		
		//set label for correct scenario
		if date > Calendar.current.date(byAdding: comp, to: Date())! {
			//if too far, set blank
			countdownLabel.text = ""
			self.backgroundColor = UIColor.white
		} else if date > Date() {
			//if within a day, set countdown
			countdownLabel.text = stringFromTimeInterval(interval: date.timeIntervalSince(Date()))
			self.backgroundColor = UIColor.FlatColor.Yellow.Energy
		} else {
			//if past, clear label, color cell and set timer to be removed
			countdownLabel.text = ""
			self.backgroundColor = UIColor.FlatColor.Blue.BadBoyBlue
			timeCounter = 0
		}
	}

	//remove formatting for reuse
	override func prepareForReuse() {
		super.prepareForReuse()
		timer?.invalidate()
		timer = nil
		countdownLabel.text = ""
	}
	
	// Configure the view for the selected state
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
	
	//convert time difference into string to be displayed as countdown
	func stringFromTimeInterval(interval: TimeInterval) -> String {
		let countdownFormatter = NumberFormatter()
		countdownFormatter.minimumIntegerDigits = 2
		let hours = Int(interval) / 3600
		let minutes = Int(interval) / 60 % 60
		let seconds = Int(interval) % 60
		return countdownFormatter.string(from: NSNumber.init(value: hours))! + ":" + countdownFormatter.string(from: NSNumber.init(value: minutes))! + ":" + countdownFormatter.string(from: NSNumber.init(value: seconds))!
	}


}

//create colors to use for event scenarios
extension UIColor {
	//init with RGB values
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")
		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}
	
	//init with hex values
	convenience init(netHex:Int) {
		self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
	}
	
	//default colors
	struct FlatColor {
		struct Green {
			static let Fern = UIColor(netHex: 0x6ABB72)
			static let BadboyGreen = UIColor(netHex: 0xBADBAD)
			static let MountainMeadow = UIColor(netHex: 0x3ABB9D)
			static let ChateauGreen = UIColor(netHex: 0x4DA664)
			static let PersianGreen = UIColor(netHex: 0x2CA786)
		}
		
		struct Blue {
			static let PictonBlue = UIColor(netHex: 0x5CADCF)
			static let Mariner = UIColor(netHex: 0x3585C5)
			static let CuriousBlue = UIColor(netHex: 0x4590B6)
			static let BadBoyBlue = UIColor(netHex: 0x5d9fd5)
			static let Chambray = UIColor(netHex: 0x485675)
			static let BlueWhale = UIColor(netHex: 0x29334D)
		}
		
		struct Violet {
			static let Wisteria = UIColor(netHex: 0x9069B5)
			static let BlueGem = UIColor(netHex: 0x533D7F)
		}
		
		struct Yellow {
			static let Energy = UIColor(netHex: 0xF2D46F)
			static let Turbo = UIColor(netHex: 0xF7C23E)
		}
		
		struct Orange {
			static let NeonCarrot = UIColor(netHex: 0xF79E3D)
			static let Sun = UIColor(netHex: 0xEE7841)
		}
		
		struct Red {
			static let TerraCotta = UIColor(netHex: 0xD8978A)
			static let Valencia = UIColor(netHex: 0xCC4846)
			static let Cinnabar = UIColor(netHex: 0xDC5047)
			static let WellRead = UIColor(netHex: 0xB33234)
			static let BadBoyRed = UIColor(netHex: 0xffcccc)
		}
		
		struct Gray {
			static let AlmondFrost = UIColor(netHex: 0xA28F85)
			static let WhiteSmoke = UIColor(netHex: 0xEFEFEF)
			static let Iron = UIColor(netHex: 0xD1D5D8)
			static let IronGray = UIColor(netHex: 0x75706B)
		}
	}
}
