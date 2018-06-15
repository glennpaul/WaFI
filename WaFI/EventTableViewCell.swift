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
	
	var expiryTimeInterval: TimeInterval? {
		didSet {
			startTimer()
		}
	}
	
	private func startTimer() {
		if let interval = expiryTimeInterval {
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
		
		guard timeCounter >= 0 else {
			timer?.invalidate()
			timer = nil
			return
		}
		if date > Calendar.current.date(byAdding: comp, to: Date())! {
			countdownLabel.text = ""
		} else if date > Date() {
			countdownLabel.text = stringFromTimeInterval(interval: date.timeIntervalSince(Date()))
		} else {
			countdownLabel.text = ""
			self.backgroundColor = UIColor.cyan
		}
		
		timeCounter -= 1
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		
		timer?.invalidate()
		timer = nil
		countdownLabel.text = ""
		self.backgroundColor = UIColor.white
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
		self.indentationWidth = -15
        // Initialization code
    }
	
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
	
	
	func stringFromTimeInterval(interval: TimeInterval) -> String {
		let countdownFormatter = NumberFormatter()
		countdownFormatter.minimumIntegerDigits = 2
		let hours = Int(interval) / 3600
		let minutes = Int(interval) / 60 % 60
		let seconds = Int(interval) % 60
		return countdownFormatter.string(from: NSNumber.init(value: hours))! + ":" + countdownFormatter.string(from: NSNumber.init(value: minutes))! + ":" + countdownFormatter.string(from: NSNumber.init(value: seconds))!
	}

}
