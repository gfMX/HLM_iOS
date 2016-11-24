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

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var imageFaceProfile: UIImageView!
    @IBOutlet weak var imageHLMProfile: UIImageView!
    @IBOutlet weak var labelWelcome: UILabel!
    @IBOutlet weak var button_uploadImages: UIButton!
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    @IBOutlet weak var switch_userVisible: UISwitch!
    @IBOutlet weak var switch_gps: UISwitch!

    @IBOutlet weak var text_displayName: UITextField!
    @IBOutlet weak var label_displayName: UILabel!
    @IBOutlet weak var label_userVisible: UILabel!
    @IBOutlet weak var label_gps: UILabel!
    
    var user: FBSDKProfile!
    var fireUser: FIRUser!
    var facebookAccessToken: FBSDKAccessToken!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
        fireUser = FireConnection.fireUser

        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(imageTapped(img:)))
        imageHLMProfile.isUserInteractionEnabled = true
        imageHLMProfile.addGestureRecognizer(tapGestureRecognizer)
        
        imageHLMProfile.layer.borderWidth = 10
        imageHLMProfile.layer.masksToBounds = false
        imageHLMProfile.layer.borderColor = UIColor.lightGray.cgColor
        imageHLMProfile.layer.cornerRadius = imageHLMProfile.frame.height/1.75
        imageHLMProfile.clipsToBounds = true
        
        text_displayName.delegate = self
        text_displayName.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingDidEnd)
   
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: General Functions
    
    func updateUI(){
        facebookAccessToken = FBSDKAccessToken.current() ?? nil
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                if (FireConnection.fireUser == nil){
                    FireConnection.fireUser = user
                    print("User Assigned from Login Screen")
                }
                self.fireUser = FireConnection.fireUser
                print(self.fireUser.uid)
                
                let profilePicURL = self.fireUser.photoURL ?? nil
                let profilleName = self.fireUser.displayName ?? nil
                
                if profilleName != nil {
                    self.text_displayName.text = profilleName
                }
                
                if profilePicURL != nil {
                    Helper.loadImageFromUrl(url: (profilePicURL?.absoluteString)!, view: self.imageHLMProfile)
                    self.imageHLMProfile.contentMode = UIViewContentMode.scaleAspectFill;
                }
                let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"first_name,email, picture.type(large)"])
                graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                    let data:[String:AnyObject] = result as! [String : AnyObject]
                    let strFirstName: String = (data["first_name"]!) as! String
                    
                    let picture = data["picture"]! as? NSDictionary
                    let strPictureURL = ((picture?.object(forKey: "data") as AnyObject).object(forKey: "url")) as! String
                    
                    print("Now the data: ")
                    print(strPictureURL)
    
                    self.labelWelcome.text = "Welcome, \(strFirstName)"
                    Helper.loadImageFromUrl(url: strPictureURL, view: self.imageFaceProfile)
                    self.imageFaceProfile.contentMode = UIViewContentMode.scaleAspectFit;
                })
                
                self.imageFaceProfile.isHidden = false
                self.text_displayName.isHidden = false
                self.label_displayName.isHidden = false
                
                self.label_userVisible.isHidden = false
                self.label_gps.isHidden = false
                self.switch_gps.isHidden = false
                self.switch_userVisible.isHidden = false
                self.button_uploadImages.isHidden = false
            } else {
                // No user is signed in.
                self.imageHLMProfile.image = #imageLiteral(resourceName: "defaultPhoto")
                self.imageFaceProfile.image = nil
                self.imageFaceProfile.isHidden = true
                self.text_displayName.isHidden = true
                self.label_displayName.isHidden = true
                
                self.label_userVisible.isHidden = true
                self.label_gps.isHidden = true
                self.switch_gps.isHidden = true
                self.switch_userVisible.isHidden = true
                self.button_uploadImages.isHidden = true
            }
        }
    }
    
    // MARK: Login Button Delegate
    
    func onProfileUpdated(notification: NSNotification){
       print ("Facebook Profile Updated")
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
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if (error != nil){
                    print("There was an error Loggin into Firebase")
                } else{
                    print("Logged into Firebase")
                    
                }
                self.updateUI()
            }
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
    
    func textFieldDidChange(_ sender : UITextField) {
        if fireUser != nil {
            print("Display Name Changed!")
            let fireRef = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("alias")
            fireRef.setValue(sender.text)
            
            //Update Firebase Profile: DisplayName
            let user = FIRAuth.auth()?.currentUser
            if let user = user {
                let changeRequest = user.profileChangeRequest()
                changeRequest.displayName = sender.text
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Display name couldn't be updated!")
                        print(error)
                    } else {
                        print ("Display Name Updated!")
                    }
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true;
    }
    
    func imageTapped(img: AnyObject){
        if fireUser != nil {
            self.performSegue(withIdentifier: "HLMProfilePic", sender: self)
        } else {
            print("Missing credentials to Access Fire Images")
        }
    }
    
    @IBAction func funcUploadImages(_ sender: UIButton) {
        if fireUser != nil && facebookAccessToken != nil {
            self.performSegue(withIdentifier: "HLMUploadImages", sender:self)
        } else {
            print("Missing credentials to Access Facebook Images")
        }
        
    }
    

}
