//
//  UsersViewController.swift
//  HotLikeMe
//
//  Created by developer on 30/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import Toast_Swift

class UsersViewController: UIViewController {
    var user = FIRAuth.auth()?.currentUser
    
    var flagOne = false
    var flagTwo = false
    
    var shuffledFlag = false
    var likeUserFlag = false
    var userIds = [String]()
    var currentUser: Int = 0
    let defaults = UserDefaults.standard
    var oldRating = 0
    var myRatingOfTheUser = 0
    
    var myCurrentLocation: CLLocation!
    
    let screenParts = 13
    var screenSize = UIScreen.main.bounds
    var displayPic_originalPosition: CGPoint!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var user_displayName: UILabel!
    @IBOutlet weak var user_displayPic: UIImageView!
    @IBOutlet weak var user_description: UITextView!
    
    @IBOutlet weak var user_ratingBar: RatingControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        getUsersList()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        if user == nil {
            user = FIRAuth.auth()?.currentUser
        } else {
            print("👤 Logged")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func getUsersList(){
        resetFlags()
        
        let lookingFor = defaults.string(forKey: "defLookingfor")!
        let gpsEnabled = defaults.bool(forKey: "defGPS")
        let ref = FIRDatabase.database().reference()
        displayPic_originalPosition = user_displayPic.frame.origin
        
        print("Display Pic Original Position: \(displayPic_originalPosition)")
        print("Screen Size: \(screenSize.size)")
        
        print("👀 For: \(lookingFor) GPS 📡: \(gpsEnabled)")
        print("--------------------------------")
        
        if user != nil {
            ref.child("groups").child(lookingFor).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                if value?.count != self.userIds.count{
                    self.userIds = value?.allKeys as! [String]
                    self.shuffledFlag = false
                    self.currentUser = 0
                    print("👥 leave/arrive at the area")
                    //print("Data: \(self.userIds)")
                }
                
                if self.userIds.count > 0 {
                    if !self.shuffledFlag {
                        self.userIds.shuffle()
                        self.shuffledFlag = true
                    }
                    
                    self.getUserDetails(currentUser: self.currentUser)
                    
                    //Check if more 👥 are 👀, if not, set count to Zero
                    if self.currentUser + 1 < self.userIds.count {
                        self.currentUser += 1
                    } else {
                        self.currentUser = 0
                    }
                    print("Next 👤: \(self.currentUser) Total 👥: \(self.userIds.count)")
                } else{
                    print("There are no 👥 Around")
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func getUserDetails(currentUser: Int){
        let ref = FIRDatabase.database().reference()
        let currentUser = currentUser
        if user != nil {
            FireConnection.setCurrentUserId(id: userIds[currentUser])
            
            self.user_displayPic.image = nil
            ref.child("users").child(userIds[currentUser]).child("preferences").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                
                let alias = value?.value(forKey: "alias") as? String
                let description = value?.value(forKey: "description") as? String
                let profilePic = value?.value(forKey: "profile_pic_storage") as? String
                self.likeUserFlag = (value?.value(forKey: "visible") as? Bool)!
                
                print("Like 👤: \(self.likeUserFlag)")
                print(value ?? "No value found for that 👤")
                
                self.user_displayName.text = alias
                self.user_description.text = description
                
                FireConnection.storageReference.child(self.userIds[currentUser]).child("/images/image_" + profilePic! + ".jpg").downloadURL { (URL, error) -> Void in
                    if (error != nil) {
                        print ("An ❌ ocurred!")
                    } else {
                        Helper.loadImageFromUrl(url: (URL?.absoluteString)!, view: self.user_displayPic)
                        self.user_displayPic.contentMode = UIViewContentMode.scaleAspectFit;
                    }
                }
                
                let ref = FIRDatabase.database().reference().child("users").child(self.userIds[currentUser]).child("user_rate")
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    self.myRatingOfTheUser = value?.value(forKey: (self.user?.uid)!) as! Int? ?? 0
                    self.oldRating = self.myRatingOfTheUser
                    self.user_ratingBar.rating = self.myRatingOfTheUser 
                    
                    //print("All values: \(value)")
                    print("⭐️ Current 👤 Rating: \(self.myRatingOfTheUser) ⭐️")
                })
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func updateRating(rating: Int, likeUser: Bool){
        let user = FIRAuth.auth()?.currentUser
        
        if user != nil {
            let currentUserId = FireConnection.getCurrentUserId()
            let dbRef = FIRDatabase.database().reference()
            FireConnection.setGlobalUserRating(rating: rating)
            
            dbRef.child("users").child(currentUserId).child("user_rate").child((user?.uid)!).setValue(rating)
            if likeUser {
                dbRef.child("users").child((user?.uid)!).child("like_user").child(currentUserId).setValue(likeUser)
            } else{
                 dbRef.child("users").child((user?.uid)!).child("like_user").child(currentUserId).setValue(nil)
            }
            print("👤 Rated 👍:  ⭐️\(rating) ⚠️ Like: \(likeUser)")
            checkIfWeLike(currentUserId: currentUserId, like: likeUser)
        }
    }
    
    func checkIfWeLike(currentUserId: String, like: Bool){
        let user = FIRAuth.auth()?.currentUser
        
        if user != nil {
            //let currentUserId = FireConnection.getCurrentUserId()
            let dbRef = FIRDatabase.database().reference()
            
            dbRef.child("users").child(currentUserId).child("like_user").observeSingleEvent(of: .value, with: { (snapshot) in
                //let value = snapshot.value as? NSDictionary
                let weLike: Bool!
                if like && snapshot.hasChild((user?.uid)!){
                    weLike = true
                    print("We like! ✅")
                } else {
                    weLike = false
                    print("We don't Like 🚷")
                }
                print("👥 like each other: \(weLike)")
                 self.checkChat(currentUserId: currentUserId, weLike: weLike)
            })
        }
    }
    
    func checkChat(currentUserId: String, weLike: Bool){
        let user = FIRAuth.auth()?.currentUser
        
        if user != nil {
            let dbRef = FIRDatabase.database().reference()
            
            dbRef.child("users").child((user?.uid)!).child("my_chats").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if weLike && !snapshot.hasChild(currentUserId){
                    let ucid = UUID().uuidString
                    let chatUid = "chat_" + ucid
                    dbRef.child("users").child(currentUserId).child("my_chats").child((user?.uid)!).setValue(chatUid)
                    dbRef.child("users").child((user?.uid)!).child("my_chats").child(currentUserId).setValue(chatUid)
                } else if weLike && snapshot.hasChild(currentUserId){
                    print("💬 exists with ID: \(value?.value(forKey: currentUserId))")
                } else if !weLike && snapshot.hasChild(currentUserId){
                    //If chat exists but Users don't like each other anymore 🚷
                    let currentChatId = value?.value(forKey: currentUserId) as! String
                    print("💬 exists with ID: \(currentChatId) but we don't like anymore 🚷")
                    dbRef.child("users").child(currentUserId).child("my_chats").child((user?.uid)!).setValue(nil)
                    dbRef.child("users").child((user?.uid)!).child("my_chats").child(currentUserId).setValue(nil)
                    
                    dbRef.child("chats").child(currentChatId).setValue(nil)
                    dbRef.child("chats_resume").child(currentChatId).setValue(nil)
                    print("💬 was ❌")
                }
                //After ✅✅ get New 👤 on View
                self.getUsersList()
            })
        }
    }
    
    // MARK: Actions
    
    @IBAction func dragCard(_ sender: UIPanGestureRecognizer) {
        var userRated = self.myRatingOfTheUser
        let view = sender.view
        let position = (sender.view?.frame.midY)!
        let translation = sender.translation(in: self.view)
        let onePart = containerView.frame.height / CGFloat(screenParts)
        
        switch sender.state {
            case UIGestureRecognizerState.began:
                print("------> Began: \(position) <------")
                //oldRate = self.myRatingOfTheUser
                break;
            
            case UIGestureRecognizerState.changed:
                containerView.sendSubview(toBack: view!)
                
                view?.center = CGPoint(x:(view?.center.x)! + translation.x,
                                       y:(view?.center.y)! + translation.y)

                if (position) < onePart {
                    userRated = 5
                } else if (position) < onePart * 2 {
                    userRated = 4
                } else if (position) < onePart * 3 {
                    userRated = 3
                } else if (position) < onePart * 4 {
                    userRated = 2
                } else if (position) < onePart * 5 {
                    userRated = 1
                    likeUserFlag = true
                    if !flagOne {
                        self.view.makeToast("I'll like to get in Touch"/*, duration: 2.0, position: .bottom*/)
                        flagOne = true
                        flagTwo = false
                    }
                } else if (position) < onePart * 6 {
                    print("Part 6 Neutral ZONE")
                    userRated = self.oldRating
                    //Drag the image to the center: Not implemented yet

                    //Mid part No hcange on users
                } else if (position) < onePart * 7 {
                    userRated = 1
                    likeUserFlag = false
                    if !flagTwo {
                        self.view.makeToast("I don't want to get in Touch"/*, duration: 2.0, position: .bottom*/)
                        flagOne = false
                        flagTwo = true
                    }
                } else if (position) < onePart * 8 {
                    userRated = 2
                } else if (position) < onePart * 9 {
                    userRated = 3
                } else if (position) < onePart * 10 {
                    userRated = 4
                } else if (position) < onePart * 11 {
                    userRated = 5
                } else if (position) < onePart * 12 {
                    //Not in use
                } else if (position) < onePart * 13 {
                    //Not in use
                }
                
                self.user_ratingBar.rating = userRated
                self.myRatingOfTheUser = userRated

                break;
            
            case UIGestureRecognizerState.ended:
                print("👤 ⭐️: \(self.myRatingOfTheUser) ⚠️ Like 👤: \(likeUserFlag)")
                print("------> Ended <------")
            
                view?.frame.origin = CGPoint(x:(displayPic_originalPosition?.x)!, y:(displayPic_originalPosition?.y)!)
                updateRating(rating: userRated, likeUser: likeUserFlag)
                //getUsersList()
                
                break;
            
            default:
                //Nothing to do here
                break;
        }
        
        sender.setTranslation(CGPoint.zero, in: self.view)
        
    }
    
    func resetFlags(){
        flagOne = false
        flagTwo = false
    }
    
    @IBAction func reloadUser(_ sender: UIBarButtonItem) {
        getUsersList()
        print("❓ for a new 👤")
    }
    
}


// MARK: Estensions

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
