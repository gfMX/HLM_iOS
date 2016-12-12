//
//  Message.swift
//  FireChat-Swift
//
//  Created by Katherine Fang on 8/20/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

import UIKit
import Foundation
import JSQMessagesViewController


class Message: NSObject, JSQMessageData {
    var text_: String?
    var senderDisplayName_: String?
    var userId: String?
    var timeStamp: Date?
    var name: String?
    var isMediaMessage_: Bool?
    var photoUrl: String?
    
    init(text: String?, userId: String?, name: String?, photoUrl: String?, timeStamp: Date?) {
        self.text_ = text
        self.userId = userId
        self.timeStamp = timeStamp
        self.name = name
        self.senderDisplayName_ = name
        self.photoUrl = photoUrl
    }
    
    func text() -> String? {
        return text_
    }

    func senderId() -> String? {
        return userId
    }
    
    func date() -> Date? {
        return timeStamp
    }
    
    func senderDisplayName() -> String? {
        return name
    }
    
    func getPhotoUrl() -> String? {
        return photoUrl
    }
    
    func isMediaMessage() -> Bool {
        return false //isMediaMessage_!
    }

    
    func messageHash() -> UInt {
        return UInt(self.hash)
    }
}
