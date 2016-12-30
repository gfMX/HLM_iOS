//
//  ChatUserListTableViewController.swift
//  HotLikeMe
//
//  Created by developer on 07/12/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase
import RNCryptor
import Toast_Swift

import AVFoundation
import UserNotifications
import UserNotificationsUI

class ChatUserListTableViewController: UITableViewController {

    var ref:FIRDatabaseReference!
    var ref1:FIRDatabaseReference!
    var user:FIRUser!
    
    var listUsers = [String]()
    var listChats = [String]()
    var listMessages = [String]()
    var users = [Users]()
    
    var flagDataLoaded = false
    var deleteUserIndexPath: IndexPath? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        ref1 = FIRDatabase.database().reference()
        user = FIRAuth.auth()?.currentUser

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        user = FIRAuth.auth()?.currentUser
        
        if currentReachabilityStatus == .notReachable{
            noInternetAlert()
        }
        
        if user != nil {
            getActiveChats()
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return users.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "userCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ChatUserCellTableViewCell

        // Configure the cell...
        cell.chat_userName.text = users[indexPath.item].name
        cell.chat_lastMessage.text = listMessages[indexPath.item] //users[indexPath.item].message
        Helper.loadImageFromUrl(url: users[indexPath.item].photo, view: cell.chat_userImage, type: "circle")
        
        return cell
    }
 
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        // Return false if you do not want the specified item to be editable.
        return true
    }
 

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            self.deleteUserIndexPath = indexPath
            
            let alert = UIAlertController(title: "Delete Chat with: \(users[indexPath.item].name)", message: "Are you sure you want to permanently delete the Selected User, all Conversations an any contact with her/him will be lost.", preferredStyle: .actionSheet)
            let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteUser)
            let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeleteUser)
            
            alert.addAction(DeleteAction)
            alert.addAction(CancelAction)
            
            // Support display in iPad
            alert.popoverPresentationController?.sourceView = self.view
            
            self.present(alert, animated: true, completion: nil)

        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    func handleDeleteUser(alertAction: UIAlertAction!) -> Void {
        print("Deleting ❌ 👤")
        if let indexPath = self.deleteUserIndexPath {
            
            let dbRef = FIRDatabase.database().reference()
            dbRef.child("users").child(user.uid).child("like_user").child(users[indexPath.item].uid).setValue(nil)
            dbRef.child("users").child(user.uid).child("my_chats").child(users[indexPath.item].uid).setValue(nil)
            dbRef.child("users").child(users[indexPath.item].uid).child("my_chats").child(user.uid).setValue(nil)
            dbRef.child("chats_resume").child(users[indexPath.item].chatid).setValue(nil)
            dbRef.child("chats").child(users[indexPath.item].chatid).setValue(nil)
            
            print("👤: \(self.users[indexPath.item].name) Deleted ❌")
            self.tableView.beginUpdates()
            
            users.remove(at: indexPath.item)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            self.deleteUserIndexPath = nil
            
            self.tableView.endUpdates()
        }
    }
    
    func cancelDeleteUser(alertAction: UIAlertAction!) {
        self.deleteUserIndexPath = nil
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let userChat = sender as? Users {
            let chatVc = segue.destination as! ChatHLMViewController
            chatVc.senderDisplayName = userChat.name
            chatVc.senderId = user.uid
            
            chatVc.userChat = userChat
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if user != nil && currentReachabilityStatus != .notReachable {
            if users[(indexPath as NSIndexPath).row].uid != ""{
                let userChat = users[(indexPath as NSIndexPath).row]
                print("User Name: \(userChat.name)")
                self.performSegue(withIdentifier: "HLMChat", sender: userChat)
            } else {
                print("⚠️ Something went wrong ❌")
                self.view.makeToast("Sorry, please try again, we're having a delay...", duration: 2.0, position: .center)
            }
        } else {
            noInternetAlert()
        }
    }
    
    func getActiveChats(){
        ref.child("users").child(user.uid).child("my_chats").observe(FIRDataEventType.value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            print("👥 on My Chats: \(value?.count)")
            self.listUsers = value?.allKeys as! [String]
            self.listChats = value?.allValues as! [String]
            self.listMessages = Array<String>(repeating: "", count: (value?.count)!)
            self.users = Array<Users>(repeating: Users(uid: "", chatid: "", name: "", photo: "", message: "")!, count: (value?.count)!)
            
            //print("👥 list: \(self.listUsers)")
            //print("💬 list: \(self.listChats)")
            if !self.flagDataLoaded {
                self.view.makeToast("Loading Messages", duration: 1.0, position: .center)
            }
            self.getUserChatDetails()
            print("Getting 👥 List")

        })
    }
    
    func getUserChatDetails(){
        flagDataLoaded = false
        
        for i in 0 ..< users.count {
            
            let uid = self.listUsers[i]
            let cid = self.listChats[i]
            
            // MARK: Password generator:
            let password = Helper.genPassword(keyString: cid)
            // End of password generation!
            
            self.ref1.child("users").child(uid).child("preferences").observeSingleEvent(of: .value, with: {(snapshot) in
                let value2 = snapshot.value as? NSDictionary
                
                let user_name = value2?.value(forKey: "alias") as! String
                let user_pic = value2?.value(forKey: "profile_pic_storage") as! String
                var user_message: String!
                var user_picUrl: String!
                
                //print ("Storage Pic: \(user_pic)")
                
                    self.ref.child("chats_resume").child(cid).observe(FIRDataEventType.value, with: {(snapshot) in
                        let value = snapshot.value as? NSDictionary
                    
                        user_message = (value?.value(forKey: "text") as? String) ?? "No message found"
                        let user_id = (value?.value(forKey: "userId") as? String) ?? "No message found"
                        self.listMessages[i] = user_message
                        print("User Message: \(user_message!), User Id: \(user_id)")
                        
                        //Only triggers after data loaded first time
                        let state = UIApplication.shared.applicationState
                        if state == .background {
                            // background
                        }
                        if state == .active && self.flagDataLoaded && user_id != self.user.uid {
                            // foreground
                            print("🔈 Playing Sound, New Message 🔈")
                            let systemSoundID: SystemSoundID = 1007
                            AudioServicesPlaySystemSound (systemSoundID)
                        }
                       
                        self.newMessageArrived(sender: user_name, message: user_message)
                        
                        if self.flagDataLoaded {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.tableView.reloadData()
                            }
                        }
                        
                        ///////////////////////////////////////////////////////////////
                        //Testing Zone
                        
                        //SecureMessage.decrypt(str: user_message)
                      
                        //Testing Decryption with RNCryptor:
                        do {
                            let originalData = try RNCryptor.decrypt(data: user_message.data(using: String.Encoding.utf8)!, withPassword: password)
                            print("Decrypted data: \(originalData)")
                        } catch {
                            print(error)
                        }
                        // End Testing Zone
                        ///////////////////////////////////////////////////////////////
                        
                    //SecureMessage.decrypt(str: user_message)
                    
                    FireConnection.storageReference.child(uid).child("/images/image_" + user_pic + ".jpg").downloadURL { (URL, error) -> Void in
                        if (error != nil) {
                            print ("An error ocurred!")
                        } else {
                            user_picUrl = URL?.absoluteString
                        }
                        
                        let user = Users(uid: uid, chatid: cid, name: user_name, photo: user_picUrl, message: user_message)!
                        self.users[i] = (user)
                        
                        if i == self.listUsers.count - 1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.tableView.reloadData()
                                self.flagDataLoaded = true
                            }
                        }
                        
                    }
                })
            })
        } // End of the function
    }
    
    func newMessageArrived(sender: String, message: String){
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            
            content.title = NSString.localizedUserNotificationString(forKey: sender, arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: message, arguments: nil)
            
            content.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            
            // Schedule the notification.
            let request = UNNotificationRequest(identifier: "HotLikeMe_\(sender)", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: nil)
        } else {
            // Fallback on earlier versions
        }
    }
  
    func noInternetAlert(){
        if currentReachabilityStatus == .notReachable{
            //print("Network Not Reachable")
            
            let alert = UIAlertController(title: "No Internet Connection", message: "Please check your Internet Connection and Try again.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Alert Dismissed")
            })
            alert.addAction(ok)
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func clearVars(){
        listChats.removeAll()
        listUsers.removeAll()
    }
    
    // MARK: DeInit
    deinit {
        //self.ref.child("chats_resume").removeAllObservers()
    }
    
    @IBAction func refreshUserList(_ sender: UIBarButtonItem) {
        if user != nil {
            getActiveChats()
        }
        self.tableView.reloadData()
    }
}
