//
//  ChatViewController.swift
//  HotLikeMe
//
//  Created by developer on 08/12/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    var dbRef: FIRDatabaseReference?
    var userChat: Users? {
        didSet {
            title = userChat?.name
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("Chat: \(userChat?.name)")
        self.senderId = FIRAuth.auth()?.currentUser?.uid
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

}
