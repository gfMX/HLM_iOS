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

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var scrollView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    
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
    
    @IBOutlet weak var lookingForPicker: UIPickerView!
    @IBOutlet weak var lookingDistancePicker: UIPickerView!
    
    
    var user: FBSDKProfile!
    var fireUser: FIRUser!
    var facebookAccessToken: FBSDKAccessToken!
    
    var lookingData = [String]()
    var lookingDistance = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
        fireUser = FireConnection.fireUser
        
        lookingData = ["Both", "Girls", "Boys"]
        lookingDistance = ["100m", "250m", "1.0km", "5.0km", "10.0km"]
        
        self.lookingForPicker.delegate = self
        self.lookingForPicker.dataSource = self
        self.lookingForPicker.tag = 0
        
        self.lookingDistancePicker.delegate = self
        self.lookingDistancePicker.dataSource =  self
        self.lookingDistancePicker.tag = 1

        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(imageTapped(img:)))
        imageHLMProfile.isUserInteractionEnabled = true
        imageHLMProfile.addGestureRecognizer(tapGestureRecognizer)
        
        imageHLMProfile.layer.borderWidth = 10
        imageHLMProfile.layer.masksToBounds = false
        imageHLMProfile.layer.borderColor = UIColor.lightGray.cgColor
        imageHLMProfile.layer.cornerRadius = imageHLMProfile.frame.height/1.7
        imageHLMProfile.clipsToBounds = true
        
        text_displayName.delegate = self
        text_displayName.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingDidEnd)
        
        switch_userVisible.addTarget(self, action: #selector(switchUserVisibleChanged), for: UIControlEvents.valueChanged)
        switch_gps.addTarget(self, action: #selector(switchGPSEnabledChanged), for: UIControlEvents.valueChanged)
   
        //updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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

    

    
    // MARK: - Navigation
    /*
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
    
    func switchUserVisibleChanged(sender: UISwitch){
        print("User Visible: " + sender.isOn.description)
        if fireUser != nil {
            FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("visible").setValue(sender.isOn)
        }
    }
    
    func switchGPSEnabledChanged(sender: UISwitch){
        print("GPS Enabled: " + sender.isOn.description)
        if fireUser != nil {
            FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("gps_enabled").setValue(sender.isOn)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        var count = 0
        if pickerView.tag == 0 {
            count = lookingData.count
        } else if pickerView.tag == 1 {
            count = lookingDistance.count
        }
        return count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return lookingData[row]
        } else if pickerView.tag == 1 {
            return lookingDistance[row]
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        if pickerView.tag == 0{
            print("Looking for: " + lookingData[row].description)
            var lookingFor: String!
        
            if row == 0 {
                lookingFor = "both"
            } else if row == 1 {
                lookingFor = "female"
            } else{
                lookingFor = "male"
            }
        
            let fireRef = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("looking_for")
            fireRef.setValue(lookingFor)
        } else if pickerView.tag == 1 {
            print("Looking distance: " + lookingDistance[row].description)
            
            var lookDistance: Int!
            switch lookingDistance[row] {
            case "100m":
                lookDistance = 100
            case "250m":
                lookDistance = 250
            case "1.0km":
                lookDistance = 1000
            case "5.0km":
                lookDistance = 5000
            case "10.0km":
                lookDistance = 10000
            default:
                lookDistance = 100
            }
            
            let fireRef = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("sync_distance")
            fireRef.setValue(lookDistance)
            print("Looking distance in meters: " + lookDistance.description)
            
        }
        
        self.view.endEditing(true)
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
    
    @IBAction func scrollToSettings(_ sender: UIButton) {
        
    }
    
    

}
