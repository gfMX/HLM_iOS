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
    var userIdsRaw = [String]()
    var currentUser: Int = 0
    let defaults = UserDefaults.standard
    var oldRating = 0
    var myRatingOfTheUser = 0
    
    var myCurrentLocation: CLLocation!
    
    let screenParts = 13
    var screenSize = UIScreen.main.bounds
    var displayPic_originalPosition: CGPoint!
    var displayPic_originalCenter: CGPoint!
    
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
        if currentReachabilityStatus == .notReachable{
            Helper.checkInternetReachability(view: self)
        }
        
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
        userIds.removeAll()
        
        let lookingFor = defaults.string(forKey: "defLookingfor") ?? "both"
        let gpsEnabled = defaults.bool(forKey: "defGPS")
        let showMe = defaults.bool(forKey: "defVisible")
        let maxDistance = defaults.double(forKey: "defSyncDistance")
        let ref = FIRDatabase.database().reference()
        displayPic_originalPosition = user_displayPic.frame.origin
        displayPic_originalCenter = user_displayPic.center
        
        print("Display Pic Original Position: \(displayPic_originalPosition)")
        print("Screen Size: \(screenSize.size)")
        
        print("👀 For: \(lookingFor) GPS 📡: \(gpsEnabled) Distance 🛣: \(maxDistance)")
        print("-------------------------------------------------")
        
        if user != nil {
            ref.child("groups").child(lookingFor).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let nCount = value?.count
                self.userIdsRaw = value?.allKeys as! [String]
                
                // MARK: GPS Disaster 📡
                // Check if Location is required an looking for Users Nearby
                
                if !gpsEnabled || !showMe || FireConnection.myLocation == nil {
                    if gpsEnabled && FireConnection.myLocation == nil {
                        self.view.makeToast("Reload the List in a few Moments, we're still waiting for your current position", duration: 0.5, position: .center)
                    }
                    self.userIds = self.userIdsRaw
                    print("⚠️👀 Showing \(self.userIds.count) 👥")
                    self.shuffledFlag = false
                    self.currentUser = 0
                    self.getTheUser()
                } else {
                    let myCurrentLocation = FireConnection.myLocation
                    let userReference = FIRDatabase.database().reference().child("users")
                    for i in 0 ..< nCount! {
                        userReference.child(self.userIdsRaw[i]).child("location_last").observeSingleEvent(of: .value, with: {(snapshot) in
                            //print("Snapshot: \(snapshot)")
                            
                            let value2 = snapshot.value as? NSDictionary!
                            let latitude = value2?.value(forKey: "loc_latitude")
                            let longitude = value2?.value(forKey: "loc_longitude")
                            
                            self.myCurrentLocation = FireConnection.getCurrentLocation()
                            
                            if latitude != nil && longitude != nil{
                                print("Getting 👤 position ✅📡")
                                let remoteLocation = CLLocation.init(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees)
                                print("📡-----------------------:⚠️:User Location:⚠️:-----------------------📡")
                                print("👤 ID: \(self.userIdsRaw[i]) \n📡 Remote: \(remoteLocation) \n📡 Myself: \(myCurrentLocation)")
                                
                                let distanceToCurrentUser = remoteLocation.distance(from: self.myCurrentLocation)
                                print("Distance to the 👤: \(distanceToCurrentUser)")
                                
                                if distanceToCurrentUser < maxDistance {
                                    if self.userIdsRaw[i] != self.user?.uid {
                                        print("👤 is Reachable ✅")
                                        self.userIds.append(self.userIdsRaw[i])
                                        print("👤 Visible: \(self.userIdsRaw[i])")
                                    }
                                }
                                
                            } else {
                                print("👤 Not reachable, ❌📡")
                            }
                            
                            if i == nCount! - 1 {
                                print("⚠️👀 Showing \(self.userIds.count) 👥")
                                self.shuffledFlag = false
                                self.currentUser = 0
                                self.getTheUser()
                            }
                        
                            
                        }, withCancel: {(Error) in
                            print("📡 Something went wrong ❌: \(Error.localizedDescription)")
                        })
                    }
                }
                print("👥 leave/arrive at the area")
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func getTheUser(){
        if self.userIds.count > 0 {
            if !self.shuffledFlag {
                self.userIds.shuffle()
                self.shuffledFlag = true
            }
            resetFlags()
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
                        Helper.loadImageFromUrl(url: (URL?.absoluteString)!, view: self.user_displayPic, type: "square")
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
                self.getTheUser()
            })
        }
    }
    
    // MARK: Actions
    
    @IBAction func dragCard(_ sender: UIPanGestureRecognizer) {
        
        var userRated = self.myRatingOfTheUser
        let view = sender.view
        let position = (view?.frame.midY)!
        let positionX = (view?.frame.midX)!
        let positionMidX = containerView.frame.midX
        let positionMidY = containerView.frame.midY
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
                        
                        var style = ToastStyle()
                        style.messageColor = UIColor.white
                        //style.backgroundColor = UIColor.cyan
                        
                        self.view.makeToast("I'll like to get in Touch", duration: 2.0, position: .bottom, title: "LIKE", image: UIImage(named: "ic_like"), style:style) { (didTap: Bool) -> Void in
                            if didTap {
                                print("completion from tap")
                            } else {
                                print("completion without tap")
                            }
                        }
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

                        var style = ToastStyle()
                        style.messageColor = UIColor.white
                        //style.backgroundColor = UIColor.magenta

                        self.view.makeToast("I don't want to get in Touch", duration: 2.0, position: CGPoint(x: positionMidX, y:125), title: "NOP", image: UIImage(named: "ic_dislike"), style:style) { (didTap: Bool) -> Void in
                            if didTap {
                                print("completion from tap")
                            } else {
                                print("completion without tap")
                            }
                        }
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
                print("-------> Ended <-------")
            
                UIView.animate(withDuration: 2.0, delay: 0,
                               usingSpringWithDamping: 0.9,
                               initialSpringVelocity: 0.5,
                               options: [], animations: {
                                if position > positionMidY{
                                    view?.center.y += self.containerView.bounds.height
                                } else {
                                    view?.center.y -= self.containerView.bounds.height
                                }
                                if positionX > positionMidX{
                                    view?.center.x += self.containerView.bounds.width * 2
                                } else {
                                    view?.center.x -= self.containerView.bounds.width * 2
                                    //tan(self.containerView.bounds.width * .pi / 180) //self.containerView.bounds.height/1.5
                                }
              
                }, completion: nil)
                
                //view?.center = displayPic_originalCenter!
                //view?.frame.origin = CGPoint(x:(displayPic_originalPosition?.x)!, y:(displayPic_originalPosition?.y)!)
                print("New Position: \(view?.frame.origin)")
                
                updateRating(rating: userRated, likeUser: likeUserFlag)
                
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

