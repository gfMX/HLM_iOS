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

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var scrollView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    
    @IBOutlet weak var imageFaceProfile: UIImageView!
    @IBOutlet weak var imageHLMProfile: UIImageView!
    @IBOutlet weak var labelWelcome: UILabel!
    @IBOutlet weak var button_uploadImages: UIButton!
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    @IBOutlet weak var switch_userVisible: UISwitch!
    @IBOutlet weak var switch_gps: UISwitch!
    
    @IBOutlet weak var text_description: UITextView!
    @IBOutlet weak var text_displayName: UITextField!
    @IBOutlet weak var label_displayName: UILabel!
    @IBOutlet weak var label_userVisible: UILabel!
    @IBOutlet weak var label_gps: UILabel!
    
    @IBOutlet weak var label_lookingFor: UILabel!
    @IBOutlet weak var label_distanceToLook: UILabel!
    @IBOutlet weak var label_updateTime: UILabel!
    @IBOutlet weak var label_description: UILabel!
    @IBOutlet weak var lookingDistancePicker: UIPickerView!
    
    
    var user: FBSDKProfile!
    var fireUser: FIRUser!
    var facebookAccessToken: FBSDKAccessToken!
    
    var lookingData = [String]()
    var lookingTime = [String]()
    var lookingDistance = [String]()
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideAll()
        
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        facebookAccessToken = FBSDKAccessToken.current() ?? nil
        fireUser = FireConnection.fireUser
        
        lookingData = ["Both", "Girls", "Boys"]
        lookingTime = ["1 Minute", "5 Minutes", "15 Minutes", "30 Minutes", "1 Hour", "6 Hours"]
        lookingDistance = ["250m", "1.0km", "5.0km", "10.0km", "50.0km"]
        
        self.lookingDistancePicker.delegate = self
        self.lookingDistancePicker.dataSource =  self
        self.lookingDistancePicker.tag = 1

        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self

        imageHLMProfile.isUserInteractionEnabled = true
        imageHLMProfile.image = imageHLMProfile.image?.circleMask
        
        //imageHLMProfile.layer.borderWidth = 10
        //imageHLMProfile.layer.masksToBounds = false
        //imageHLMProfile.layer.borderColor = UIColor.lightGray.cgColor
        //imageHLMProfile.layer.cornerRadius = 90 //imageHLMProfile.layer.frame.width/2 //90
        //imageHLMProfile.clipsToBounds = true
        
        text_description.delegate = self
        text_displayName.delegate = self
        
        switch_userVisible.addTarget(self, action: #selector(switchUserVisibleChanged), for: UIControlEvents.valueChanged)
        switch_gps.addTarget(self, action: #selector(switchGPSEnabledChanged), for: UIControlEvents.valueChanged)
        
        //NotificationCenter.default.addObserver(self, selector:#selector(LoginViewController.updateUI), name: NSNotification.Name.FBSDKAccessTokenDidChange, object: nil)

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
        
        if facebookAccessToken != nil {
            self.button_uploadImages.isEnabled = true
        } else {
            try! FIRAuth.auth()!.signOut()
            print("👤 Logged Out, No Access Token")
        }
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                // MARK: Update UI: User signed in.
                if (FireConnection.fireUser == nil){
                    FireConnection.fireUser = user
                    print("👤 Assigned from Login Screen")
                }
                self.fireUser = FireConnection.fireUser
                print(self.fireUser.uid)
                
                let profilePicURL = self.fireUser.photoURL ?? nil
                let profilleName = self.fireUser.displayName ?? nil
                
                if profilleName != nil {
                    self.text_displayName.text = profilleName
                }
                
                if profilePicURL != nil {
                    Helper.loadImageFromUrl(url: (profilePicURL?.absoluteString)!, view: self.imageHLMProfile, type: "circle")
                }
                
                 let dbRef = FIRDatabase.database().reference()
                /***************************************************************************
                                      Getting details from Facebook
                 ***************************************************************************/
                if self.facebookAccessToken != nil {
                    
                    let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"first_name,email, picture.type(large),gender"])
                    graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                        let data:[String:AnyObject] = result as! [String : AnyObject]
                        let strFirstName: String = (data["first_name"]!) as! String
                        let gender: String = (data["gender"]!) as! String
                        
                        let picture = data["picture"]! as? NSDictionary
                        let strPictureURL = ((picture?.object(forKey: "data") as AnyObject).object(forKey: "url")) as! String
                        
                        //print("Now the data: \(data)")
                        
                        self.labelWelcome.text = "Welcome, \(strFirstName)"
                        Helper.loadImageFromUrl(url: strPictureURL, view: self.imageFaceProfile, type: "circle")
                        self.imageFaceProfile.contentMode = UIViewContentMode.scaleAspectFit
                        
                        dbRef.child("users").child(self.fireUser.uid).child("preferences").child("gender").setValue(gender)
                        self.defaults.set(gender, forKey: "defGender")
                    })
                } else {
                    self.button_uploadImages.isEnabled = false
                }
                
                /***************************************************************************
                 Next section updates al values required from Firebase if they already exist
                 ***************************************************************************/
               
                let ref = dbRef.child("users").child(self.fireUser.uid).child("preferences")
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    let boolVisible = (value?.value(forKey: "visible") as? Bool) ?? true
                    let boolGPS = (value?.value(forKey: "gps_enabled") as? Bool) ?? false
                    let textDescription = (value?.value(forKey: "description") as? String)
                    
                    let fireLookingFor = (value?.value(forKey: "looking_for") as? String) ?? "both"
                    let fireSyncDistance = (value?.value(forKey: "sync_freq") as? Int) ?? 5
                    let fireDistance = (value?.value(forKey: "sync_distance") as? Int) ?? 5000
                    
                    if boolVisible {
                        self.switch_gps.isEnabled = true
                    } else {
                        self.switch_gps.isEnabled = false
                    }
                    
                    print (value ?? "No values found")
                    print ("Description: " + textDescription!)
                    print ("Visible: " + boolVisible.description)
                    print ("GPS Enabled: " + boolGPS.description)
                    print ("Looking for: " + fireLookingFor)
                    print ("Sync Frequency: " + fireSyncDistance.description)
                    print ("Sync Distance: " + fireDistance.description)
                    
                    // MARK: Updating Defaults:
                    self.defaults.set(boolGPS, forKey: "defGPS")
                    self.defaults.set(boolVisible, forKey: "defVisible")
                    self.defaults.set(fireLookingFor, forKey: "defLookingfor")
                    self.defaults.set(fireSyncDistance, forKey: "defSyncFrequency")
                    self.defaults.set(fireDistance, forKey: "defSyncDistance")
                  
                    //Updating Switches
                    self.switch_userVisible.isOn = boolVisible
                    self.switch_gps.isOn = boolGPS
                    if textDescription != nil {
                        self.text_description.text = textDescription
                    }
                    
                    //Updating Picker with the Values of Firebase
                    switch fireLookingFor {
                    case "both":
                        self.lookingDistancePicker.selectRow(0, inComponent: 0, animated: true)
                    case "female":
                        self.lookingDistancePicker.selectRow(1, inComponent: 0, animated: true)
                    case "male":
                        self.lookingDistancePicker.selectRow(2, inComponent: 0, animated: true)
                    default:
                        print ("Nothing to do")
                    }
                    
                    switch fireDistance {
                    case 250:
                        self.lookingDistancePicker.selectRow(0, inComponent: 1, animated: true)
                    case 1000:
                        self.lookingDistancePicker.selectRow(1, inComponent: 1, animated: true)
                    case 5000:
                        self.lookingDistancePicker.selectRow(2, inComponent: 1, animated: true)
                    case 10000:
                        self.lookingDistancePicker.selectRow(3, inComponent: 1, animated: true)
                    case 50000:
                        self.lookingDistancePicker.selectRow(4, inComponent: 1, animated: true)
                    default:
                        print ("Nothing to do")
                    }
                    
                    switch fireSyncDistance {
                    case 1:
                        self.lookingDistancePicker.selectRow(0, inComponent: 2, animated: true)
                    case 5:
                        self.lookingDistancePicker.selectRow(1, inComponent: 2, animated: true)
                    case 15:
                        self.lookingDistancePicker.selectRow(2, inComponent: 2, animated: true)
                    case 30:
                        self.lookingDistancePicker.selectRow(3, inComponent: 2, animated: true)
                    case 60:
                        self.lookingDistancePicker.selectRow(4, inComponent: 2, animated: true)
                    case 360:
                        self.lookingDistancePicker.selectRow(5, inComponent: 2, animated: true)
                    default:
                        print ("Nothing to do")
                    }
                    
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
                //Updating from Firebase end!
                self.showAll()
                
            } else {
                
                /***********************************************
                // MARK: Update UI: No user signed.
                ************************************************/
                self.hideAll()
            }
        }
    }
    
    // MARK: Login Button Delegate
    
    func onProfileUpdated(notification: NSNotification){
       print ("Facebook Profile Updated")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("👤 Log process")
        if ((error) != nil){
            // Process error
            print("❌:" + error.localizedDescription)
        } else if result.isCancelled {
            // Handle cancellations
            print("Login Cancelled ❌")
        } else {
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if (error != nil){
                    print("❌ Loggin into Firebase")
                } else{
                    print("✅ Logged into Firebase")
                }
                self.updateUI()
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        try! FIRAuth.auth()!.signOut()
        print("👤 Logged Out")
    }
    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @available(iOS 10.0, *)
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if fireUser != nil {
            
            print("Display Name Changed!")
            let fireRef = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("alias")
                fireRef.setValue(textField.text)
            
            //Update Firebase Profile: DisplayName
            let user = FIRAuth.auth()?.currentUser
            if let user = user {
                let changeRequest = user.profileChangeRequest()
                changeRequest.displayName = textField.text
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("Description Begin editing")
    }
    /*
    func textViewDidChange(_ textView: UITextView) {
        print("Description Changed")
    }
    */
    func textViewDidEndEditing(_ textView: UITextView) {
        print("Description Changed")
        if fireUser != nil {
            
            print("Display Name Changed!")
            let fireRef = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("description")
            fireRef.setValue(textView.text)
        
        }
        
    }
    
    
    func switchUserVisibleChanged(sender: UISwitch){
        print("👤 Visible: " + sender.isOn.description)
        if fireUser != nil {
            let gender = defaults.string(forKey: "defGender")
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("users").child(fireUser.uid).child("preferences").child("visible").setValue(sender.isOn)
            self.defaults.set(sender.isOn, forKey: "defVisible")
            if sender.isOn {
                //switch_gps.setOn(false, animated: true)
                switch_gps.isEnabled = true
                databaseRef.child("groups").child(gender!).child(fireUser.uid).setValue(true)
                databaseRef.child("groups").child("both").child(fireUser.uid).setValue(true)
            } else {
                switch_gps.isEnabled = false
                databaseRef.child("groups").child(gender!).child(fireUser.uid).setValue(nil)
                databaseRef.child("groups").child("both").child(fireUser.uid).setValue(nil)
            }
        }
    }
    
    func switchGPSEnabledChanged(sender: UISwitch){
        print("GPS Enabled: " + sender.isOn.description)
        if fireUser != nil {
            FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("gps_enabled").setValue(sender.isOn)
            self.defaults.set(sender.isOn, forKey: "defGPS")
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        var count = 0
        if component == 0 {
            count = lookingData.count
        } else if component == 1 {
            count = lookingDistance.count
        } else if component == 2 {
            count = lookingTime.count
        }
        return count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0{
            return lookingData[row]
        } else if component == 1 {
            return lookingDistance[row]
        } else if component == 2{
            return lookingTime[row]
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){

        if component == 0{
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
            defaults.set(lookingFor, forKey: "defLookingFor")
            print("Looking for: " + lookingFor)
        }
        if component == 1 {
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
            case "50.0km":
                lookDistance = 50000
            default:
                lookDistance = 100
            }
                
            let fireRef = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("sync_distance")
            fireRef.setValue(lookDistance)
            defaults.set(lookDistance, forKey: "defSyncDistance")
            print("Looking distance in meters: " + lookDistance.description)
            
        }
        if component == 2{
            print("Sync time: ")
                
            var lookTime: Int!
            switch lookingTime[row]{
                case "1 Minute":
                    lookTime = 1
                case "5 Minutes":
                    lookTime = 5
                case "15 Minutes":
                    lookTime = 15
                case "30 Minutes":
                    lookTime = 30
                case "1 Hour":
                    lookTime = 60
                case "6 Hours":
                    lookTime = 60 * 6
                default:
                    lookTime = 5
            }
                
            let fireRefTime = FireConnection.databaseReference.child("users").child(fireUser.uid).child("preferences").child("sync_freq")
            fireRefTime.setValue(lookTime)
            defaults.set(lookTime, forKey: "defSyncFrequency")
            print ("Time between Sync: " + lookTime.description)
        }
    
        self.view.endEditing(true)
    }
    func showAll(){
        self.imageFaceProfile.isHidden = false
        self.text_displayName.isHidden = false
        self.label_displayName.isHidden = false
        
        self.label_userVisible.isHidden = false
        self.label_gps.isHidden = false
        self.switch_gps.isHidden = false
        self.switch_userVisible.isHidden = false
        self.button_uploadImages.isHidden = false
        
        self.label_lookingFor.isHidden = false
        self.label_distanceToLook.isHidden = false
        self.label_updateTime.isHidden = false
        self.lookingDistancePicker.isHidden = false
        self.label_description.isHidden = false
        self.text_description.isHidden = false
    }
    
    func hideAll(){
        self.imageHLMProfile.image = #imageLiteral(resourceName: "defaultPhoto").circleMask
        self.imageFaceProfile.image = nil
        
        self.imageFaceProfile.isHidden = true
        self.text_displayName.isHidden = true
        self.label_displayName.isHidden = true
        
        self.label_userVisible.isHidden = true
        self.label_gps.isHidden = true
        self.switch_gps.isHidden = true
        self.switch_userVisible.isHidden = true
        self.button_uploadImages.isHidden = true
        
        self.label_lookingFor.isHidden = true
        self.label_distanceToLook.isHidden = true
        self.label_updateTime.isHidden = true
        self.lookingDistancePicker.isHidden = true
        self.label_description.isHidden = true
        self.text_description.isHidden = true
    }
    
}


