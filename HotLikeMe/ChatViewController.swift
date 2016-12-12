//
//  ChatViewController.swift
//  HotLikeMe
//
//  Created by developer on 08/12/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase

//@objc(ChatViewController)
class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var currentUser: FIRUser!
    var dbRef: FIRDatabaseReference?
    var chatId: String!
    var senderId: String!
    var senderDisplayName: String!
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    var userChat: Users? {
        didSet {
            title = userChat?.name
        }
    }
    
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var messageRef: FIRDatabaseReference?

    @IBOutlet weak var clientTable: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")

        // Do any additional setup after loading the view.
        
        currentUser = FIRAuth.auth()?.currentUser
        senderId = currentUser?.uid
        chatId = userChat?.chatid //"chat_0958f70a-3500-48dc-a687-aa472f48504c"
        
        print("Chat: \(senderId!) Chat ID: \(chatId!)")
        
        configureDatabase()
        configureStorage()
        configureRemoteConfig()
        fetchConfig()
        
    }
    
    deinit {
        self.ref.child("chats").child(chatId!).removeObserver(withHandle: _refHandle)
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        
        _refHandle = self.ref.child("chats").child(chatId!).observe(.childAdded, with: { [weak self] (snapshot) -> Void in
            
            guard let strongSelf = self else { return }
            strongSelf.messages.append(snapshot)
            print("Snapshot: \(snapshot) Count: \(strongSelf.messages.count)")
            strongSelf.clientTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
            self?.clientTable.reloadData()
            
        })
    }
    
    func configureStorage() {
        let storageUrl = FIRApp.defaultApp()?.options.storageBucket
        storageRef = FIRStorage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    func configureRemoteConfig() {
        remoteConfig = FIRRemoteConfig.remoteConfig()
        // Create Remote Config Setting to enable developer mode.
        // Fetching configs from the server is normally limited to 5 requests per hour.
        // Enabling developer mode allows many more requests to be made per hour, so developers
        // can test different config values during development.
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
    }
    
    func fetchConfig() {
        var expirationDuration: Double = 3600
        // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
        // the server.
        if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
            expirationDuration = 0
        }
        
        // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
        // fetched and cached config would be considered expired because it would have been fetched
        // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
        // throttling is in progress. The default expiration duration is 43200 (12 hours).
        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
            if (status == .success) {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
                let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
                if (friendlyMsgLength.source != .static) {
                    self.msglength = friendlyMsgLength.numberValue!
                    print("Friendly msg length config: \(self.msglength)")
                }
            } else {
                print("Config not fetched")
                print("Error \(error)")
            }
        }
    }
    
    

    @IBAction func didSendMessage(_ sender: UIButton) {
        _ = textFieldShouldReturn(textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= self.msglength.intValue // Bool
    }
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print ("💬 \(messages.count)")
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("Doing things 👀")
        
        // Dequeue cell
        let cell = self.clientTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        // Unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
        print("Content of Snapshot: \(messageSnapshot)")
        
        let message = messageSnapshot.value as! NSDictionary //, String, String, String, Bool
        print("Content of Message: \(message)")
        
        
        let name = message[Constants.MessageFields.name] as! String!
        if let imageURL = message[Constants.MessageFields.imageURL] {
            if (imageURL as AnyObject).hasPrefix("gs://") {
                FIRStorage.storage().reference(forURL: imageURL as! String).data(withMaxSize: INT64_MAX){ (data, error) in
                    if let error = error {
                        print("Error downloading: \(error)")
                        return
                    }
                    cell.imageView?.image = UIImage.init(data: data!)
                }
            } else if let URL = URL(string: imageURL as! String), let data = try? Data(contentsOf: URL) {
                cell.imageView?.image = UIImage.init(data: data)
            }
            cell.textLabel?.text = "sent by: \(name)"
        } else {
            let text = message[Constants.MessageFields.text] as! String!
            cell.textLabel?.text = name! + ": " + text!
            cell.imageView?.image = UIImage(named: "ic_account_circle")
            if let photoURL = message[Constants.MessageFields.photoUrl], let URL = URL(string: photoURL as! String), let data = try? Data(contentsOf: URL) {
                cell.imageView?.image = UIImage(data: data)
            }
        }
        
        return cell
    }
    
    // UITextViewDelegate protocol methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        let data = [Constants.MessageFields.text: text]
        sendMessage(withData: data)
        return true
    }
    
    func sendMessage(withData data: [String: String]) {
        var mdata = data
        mdata[Constants.MessageFields.name] = currentUser.displayName
        if let photoURL = currentUser.photoURL {
            mdata[Constants.MessageFields.photoUrl] = photoURL.absoluteString
        }
        // Push data to Firebase Database
        self.ref.child("chats").child(chatId!).childByAutoId().setValue(mdata)
    }
    
    func showAlert(withTitle title:String, message:String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

}
