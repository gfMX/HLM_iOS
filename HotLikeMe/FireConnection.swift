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
    
    let storage = FIRStorage.storage()
    
    static var fireUser: FIRUser!
    static let sharedInstance = FireConnection()
    static var databaseReference: FIRDatabaseReference!
    static var storageReference: FIRStorageReference!
    //static var visibleViews = 1
    
    static var currentUserRating: Int!
    static var currentUserID: String!
    
    private init(){
        print ("Initializing Connection")
        checkFirebaseLogStatus()
    }


    func checkFirebaseLogStatus(){
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                FireConnection.fireUser = user
                FireConnection.databaseReference = FIRDatabase.database().reference()
                FireConnection.storageReference = self.storage.reference(forURL: "gs://project-6344486298585531617.appspot.com")
                //FireConnection.visibleViews = self.minViews
                print("User Looged: " + FireConnection.fireUser.uid)
            } else {
                print("Firebase User not Logged")
                FireConnection.fireUser = nil
                //FireConnection.visibleViews = self.maxViews
            }
        }
    }
    static func setGlobalUserRating(rating: Int){
        FireConnection.currentUserRating = rating
    }
    static func getGlobalUserRating() -> Int {
        return FireConnection.currentUserRating
    }
    static func setCurrentUserId(id: String){
        FireConnection.currentUserID = id
    }
    static func getCurrentUserId() -> String {
        return FireConnection.currentUserID
    }
}
