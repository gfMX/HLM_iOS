//
//  UsersViewController.swift
//  HotLikeMe
//
//  Created by developer on 30/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase

class UsersViewController: UIViewController {
    var user = FIRAuth.auth()?.currentUser
    
    var shuffledFlag = false
    var userIds = [String]()
    var currentUser: Int = 0
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var user_displayName: UILabel!
    @IBOutlet weak var user_displayPic: UIImageView!
    @IBOutlet weak var user_description: UITextView!
    
    @IBOutlet weak var user_ratingBar: RatingControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        if user == nil {
            user = FIRAuth.auth()?.currentUser
        } else {
            print("👤 Logged")
        }
        
        getUsersList()
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
        let lookingFor = defaults.string(forKey: "defLookingfor")
        let ref = FIRDatabase.database().reference()
        
        print("Looking For: \(lookingFor)")
        
        if user != nil {
            ref.child("groups").child(lookingFor!).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                if value?.count != self.userIds.count{
                    self.userIds = value?.allKeys as! [String]
                    self.shuffledFlag = false
                    self.currentUser = 0
                    print("Users leave/arrive at the area")
                    //print("Data: \(self.userIds)")
                }
                
                if self.userIds.count > 0 {
                    if !self.shuffledFlag {
                        self.userIds.shuffle()
                        self.shuffledFlag = true
                    }
                    
                    self.getUserDetails(currentUser: self.currentUser)
                    
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
                    let myRatingOfTheUser = value?.value(forKey: (self.user?.uid)!) ?? 0
                    self.user_ratingBar.rating = myRatingOfTheUser as! Int
                    
                    //print("All values: \(value)")
                    print("⭐️ Current 👤 Rating: \(myRatingOfTheUser) ⭐️")
                })
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func dragCard(_ sender: UIPanGestureRecognizer) {
        //var rotationAngle: CGFloat = 0
        let translation = sender.translation(in: self.view)
        if let view = sender.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
            
            //rotationAngle = rotationAngle + 1
            let dx = view.center.x + translation.x
            let dy = view.center.y + translation.y
            
            let angle = atan2(dx, dy)
            view.transform = CGAffineTransform(rotationAngle: angle);
        }
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @IBAction func reloadUser(_ sender: UIBarButtonItem) {
        getUsersList()
        print("Asking for a new 👤")
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
