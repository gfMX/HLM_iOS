//
//  Users.swift
//  HotLikeMe
//
//  Created by developer on 07/12/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit

class Users: NSObject, NSCoding {
    
    // MARK: Properties
    
    var name: String
    var photo: String
    var message: String
    
    // MARK: Types
    
    struct PropertyKey {
        static let nameKey = "name"
        static let photoKey = "photo"
        static let messageKey = "message"
    }
    
    // MARK: Initialization
    
    init?(name: String, photo: String, message: String) {
        self.name = name
        self.photo = photo
        self.message = message
        
        super.init()
        
        if name.isEmpty || photo.isEmpty {
            return nil
        }
    }
    
    // MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(photo, forKey: PropertyKey.photoKey)
        aCoder.encode(message, forKey: PropertyKey.messageKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let photo = aDecoder.decodeObject(forKey: PropertyKey.photoKey) as! String
        let message = aDecoder.decodeObject(forKey: PropertyKey.messageKey) as! String
        
        self.init(name: name, photo: photo, message: message)
    }
    
}
