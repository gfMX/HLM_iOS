//
//  LoginViewController.swift
//  HotLikeMe
//
//  Created by developer on 16/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate{
    
    @IBOutlet weak var imageFaceProfile: UIImageView!
    @IBOutlet weak var imageHLMProfile: UIImageView!
    @IBOutlet weak var labelWelcome: UILabel!
    @IBOutlet weak var loginButton: FBSDKLoginButton!

    
    var user: FBSDKProfile!
    var fireUser: FIRUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)

        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        
        imageHLMProfile.layer.borderWidth = 10
        imageHLMProfile.layer.masksToBounds = false
        imageHLMProfile.layer.borderColor = UIColor.lightGray.cgColor
        imageHLMProfile.layer.cornerRadius = imageHLMProfile.frame.height/1.8
        imageHLMProfile.clipsToBounds = true
   
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: General Functions
    
    func updateUI(){
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                self.fireUser = user
                print(self.fireUser.uid)
                print(self.fireUser.photoURL?.absoluteString ?? "URL Not Found")
                
                let profilePicURL = self.fireUser.photoURL ?? nil
                if profilePicURL != nil {
                    Helper.loadImageFromUrl(url: (profilePicURL?.absoluteString)!, view: self.imageHLMProfile)
                }
            } else {
                // No user is signed in.
                self.imageHLMProfile.image = nil
            }
        }
    }
    
    // MARK: Login Button Delegate
    
    func onProfileUpdated(notification: NSNotification){
       print ("Fuck you Swift!")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("User Logged In")
        if ((error) != nil)
        {
            // Process error
            print("Error:" + error.localizedDescription)
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            
            if result.grantedPermissions.contains("email")
            {
                
            }
        
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if (error != nil){
                    print("There was an error Loggin into Firebase")
                } else{
                    print("Logged into Firebase")
                    
                }
                self.updateUI()
            }

            let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"first_name,email, picture.type(large)"])
                graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                    let data:[String:AnyObject] = result as! [String : AnyObject]
                  
                    print(data)
                    
                let strFirstName: String = (data["first_name"]!) as! String
            
                //let strPictureURL: String = (data["picture"]!.data["data"]!.data["url"]! as? String)!
                self.labelWelcome.text = "Welcome, \(strFirstName)"
                //self.imageFaceProfile.image = UIImage(data: NSData(contentsOfURL: NSURL(string: strPictureURL)!)!)
                })
            
            /*if user != nil {
                let currentProfile = FBSDKProfile.current().imageURL(for: FBSDKProfilePictureMode.normal, size: CGSize(width: 120, height: 120)).absoluteString
                print("Image URL: " + currentProfile)
                Helper.loadImageFromUrl(url: currentProfile, view: imageFaceProfile)
            } else {
                print("Profile not found")
            } */
            
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        try! FIRAuth.auth()!.signOut()
        print("User Logged Out")
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
