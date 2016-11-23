//
//  FireConnection.swift
//  HotLikeMe
//
//  Created by developer on 23/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import Foundation
import Firebase

class FireConnection {
    //let minViews = 1
    //let maxViews = 3
    
    static var fireUser: FIRUser!
    static let sharedInstance = FireConnection()
    //static var visibleViews = 1
    
    private init(){
        print ("Initializing Connection")
        checkFirebaseLogStatus()
    }


    func checkFirebaseLogStatus(){
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                FireConnection.fireUser = user
                //FireConnection.visibleViews = self.minViews
                print("User Looged: " + FireConnection.fireUser.uid)
            } else {
                print("Firebase User not Logged")
                FireConnection.fireUser = nil
                //FireConnection.visibleViews = self.maxViews
            }
        }
    }
}
