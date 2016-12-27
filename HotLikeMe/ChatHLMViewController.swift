//
//  ChatViewController.swift
//  HotLikeMe
//
//  Created by developer on 08/12/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//
import UIKit
import Firebase
import RNCryptor
import Toast_Swift
import JSQMessagesViewController

@objc(ChatHLMViewController)
class ChatHLMViewController: JSQMessagesViewController {
    
    var messages = [Message]()
    private var password:String!
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    private var messageRef: FIRDatabaseReference!
    private var lastMessageRef: FIRDatabaseReference!
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    var currentUser: FIRUser!
    var dbRef: FIRDatabaseReference?
    
    var userChat: Users? {
        didSet {
            title = userChat?.name
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        //print("Chat: \(userChat?.uid)")
        self.currentUser = FIRAuth.auth()?.currentUser
        self.senderId = currentUser?.uid
        self.password = Helper.genPassword(keyString: (userChat?.chatid)!)
        
        messageRef = FIRDatabase.database().reference().child("chats").child((userChat?.chatid)!) //"chat_0958f70a-3500-48dc-a687-aa472f48504c"
        lastMessageRef = FIRDatabase.database().reference().child("chats_resume").child((userChat?.chatid)!)
        print("DB Reference: \(messageRef.description())")
        
        let currentDate = Date()
        
        // messages from someone else
        addMessage(withId: "HLMApp", name: "HotLikeMe", text: "Welcome to the Chat!", photoUrl: (currentUser?.photoURL?.absoluteString)!, date: currentDate)
        finishReceivingMessage()
        
        observeMessages()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addMessage(withId id: String, name: String, text: String, photoUrl: String, date: Date) {
        /*
        if let message = Message(text: text, userId: id, name: name, photoUrl: photoUrl, timeStamp: date) {
            messages.append(message)
        }
        */
        let message = Message(text: text, userId: id, name: name, photoUrl: photoUrl, timeStamp: date)
        messages.append(message)
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        //////////////////////////////////////////////////////////////////
        // MARK: Testing Decryption with RNCryptor
        // Everything we need to upload and decrypt Messages...
        
        //Encrypt Messages:
        let cipherString = Helper.encryptString(text: text, password: password)
        
        //Decrypt Messages:
        _ = Helper.decryptString(text: cipherString, password: password)
        
        // End Testing Zone
        //////////////////////////////////////////////////////////////////
        
        let itemRef = messageRef.childByAutoId()
        let dateString = (date.timeIntervalSince1970 * 1000).description
        let messageItem = [
            "userId": senderId!,
            "name": senderDisplayName!,
            "text": text!,
            "photoUrl": currentUser.photoURL?.absoluteString ?? "",
            "timeStamp": dateString,
            ] as [String : Any]
        
        itemRef.setValue(messageItem)
        lastMessageRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        
        print("✉️ Sent!")
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        self.view.makeToast("Sorry we are working to implement File Sharing", duration: 2.5, position: .center)
    }
    
    private func observeMessages() {
        //messageRef = channelRef!.child("messages")
        
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
           
            let messageData = snapshot.value as! NSDictionary
            
            if let id = messageData["userId"] as! String!, let name = messageData["name"] as! String!, let photoUrl = messageData["photoUrl"] as! String!, let timeStamp = messageData["timeStamp"] as! String!, let text = messageData["text"] as! String!, text.characters.count > 0 {
                
                let date = Date()
                print("Time stamp: \(timeStamp)")
                
                self.addMessage(withId: id, name: name, text: text, photoUrl: photoUrl, date: date)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of ✉️ on chat: \(messages.count)")
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.userId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.userId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
}
