//
//  EventTableViewCell.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-04.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    //MARK: Properties
	@IBOutlet weak var eventImage: UIImageView!
	@IBOutlet weak var eventName: UILabel!
	@IBOutlet weak var eventDetail: UILabel!
	@IBOutlet weak var countdownLabel: UILabel!
	
	private var timer: Timer?
	private var timeCounter: Double = 0
	var date:Date = Date()
	
	var shouldSet: TimeInterval? {
		//start timer when shouldSet indicator set
		didSet {
			startTimer()
		}
	}
	
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
	
	@objc func onComplete() {
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
		} else if date > Date() {
			//if within a dat, set countdown
			countdownLabel.text = stringFromTimeInterval(interval: date.timeIntervalSince(Date()))
		} else {
			//if past, clear label, color cell and set timer to be removed
			countdownLabel.text = ""
			self.backgroundColor = UIColor.cyan
			timeCounter = 0
		}
	}

	//remove formatting for reuse
	override func prepareForReuse() {
		super.prepareForReuse()
		timer?.invalidate()
		timer = nil
		countdownLabel.text = ""
		self.backgroundColor = UIColor.white
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
