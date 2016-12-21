//
//  RatingControl.swift
//  testIOS
//
//  Created by developer on 25/10/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase

class RatingControl: UIView {
    // MARK: Properties
    
    var rating = 0{
        didSet {
            setNeedsLayout()
        }
    }
    var ratingButtons = [UIButton]()
    let spacing = 4
    let starCount = 5
    let ratingBarSize = 45

    // MARK: Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let filledStarImage = UIImage(named: "filledStar")
        let emptyStarImage = UIImage(named: "emptyStar")
        
        for _ in 0..<starCount {
            let button = UIButton()
            
            button.setImage(emptyStarImage, for: .normal)
            button.setImage(filledStarImage, for: .selected)
            button.setImage(filledStarImage, for: [.highlighted, .selected])
            button.backgroundColor = UIColor.clear
            
            button.adjustsImageWhenHighlighted = false
            
            button.addTarget(self, action: #selector(RatingControl.ratingButtonTapped(_:)), for: .touchDown)
            ratingButtons += [button]
            addSubview(button)
        }
        
    }
    
    override func layoutSubviews() {
        //print ("Frame SIZE: ", Int(frame.size.height))
        let buttonSize = Int(frame.size.height)
        var buttonFrame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        
        for (index, button) in ratingButtons.enumerated() {
            buttonFrame.origin.x = CGFloat(index * (buttonSize + spacing))
            button.frame = buttonFrame
        }
        updateButtonSelectionStates()
    }

    override var intrinsicContentSize: CGSize {
        let buttonSize = ratingBarSize
        //let buttonSize = Int(frame.size.height)
        let width = (buttonSize + spacing) * starCount
        
        return CGSize(width: width, height: buttonSize)
    }
    // MARK: Button Action
    
    func ratingButtonTapped (_ button: UIButton){
        rating = ratingButtons.index(of: button)! + 1
        let user = FIRAuth.auth()?.currentUser
        
        if user != nil {
            let currentUserId = FireConnection.getCurrentUserId()
            let dbRef = FIRDatabase.database().reference()
            FireConnection.setGlobalUserRating(rating: rating)
            
            dbRef.child("users").child(currentUserId).child("user_rate").child((user?.uid)!).setValue(rating)
            print("--> Rating Assigned 👍: \(rating) <--")
        }
        
        updateButtonSelectionStates()
    }
    
    func updateButtonSelectionStates() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }

}
