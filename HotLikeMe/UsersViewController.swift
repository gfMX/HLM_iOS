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
    let user = FIRAuth.auth()?.currentUser
    
    var userIds = [String]()
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var user_displayName: UILabel!
    @IBOutlet weak var user_displayPic: UIImageView!
    @IBOutlet weak var user_description: UITextView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
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
                self.userIds = value?.allKeys as! [String]
                print("Data: \(self.userIds)")
                if self.userIds.count > 0 {
                    self.userIds.shuffle()
                    self.getUserDetails()
                } else{
                    print("There are no Users Around")
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func getUserDetails(){
        let ref = FIRDatabase.database().reference()
        let currentUser = 0
        if user != nil {
            ref.child("users").child(userIds[currentUser]).child("preferences").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                
                let alias = value?.value(forKey: "alias") as? String
                let description = value?.value(forKey: "description") as? String
                let profilePic = value?.value(forKey: "profile_pic_storage") as? String
                
                print(value ?? "No value found for that user")
                
                self.user_displayName.text = alias
                self.user_description.text = description
                
                FireConnection.storageReference.child(self.userIds[currentUser]).child("/images/image_" + profilePic! + ".jpg").downloadURL { (URL, error) -> Void in
                    if (error != nil) {
                        print ("An error ocurred!")
                    } else {
                        Helper.loadImageFromUrl(url: (URL?.absoluteString)!, view: self.user_displayPic)
                        self.user_displayPic.contentMode = UIViewContentMode.scaleAspectFit;
                    }
                    
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
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
