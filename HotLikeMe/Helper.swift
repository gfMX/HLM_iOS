//
//  Helper.swift
//  HotLikeMe
//
//  Created by developer on 17/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import Foundation
import UIKit

class Helper{
    
    static func loadImageFromUrl(url: String, view: UIImageView){
        
        // Create Url from string
        //print("HELPER -> URL: " + url)
        let url = NSURL(string: url)!
        
        // Download task:
        // - sharedSession = global NSURLCache, NSHTTPCookieStorage and NSURLCredentialStorage objects.
        let task = URLSession.shared.dataTask(with: url as URL) { (responseData, responseUrl, error) -> Void in
            // if responseData is not null...
            if let data = responseData{
                
                // execute in UI thread
                DispatchQueue.main.async(execute: { () -> Void in
                    view.image = UIImage(data: data)
                })
            }
        }
        
        // Run task
        task.resume()
    }
    
    static func genPassword(keyString: String) -> String {
        // MARK: Password generator:
        let passwordChain = keyString.replacingOccurrences(of: "chat_", with: "")
        let reversedChain = String(passwordChain.characters.reversed())
        let shaData = Helper.sha256(string: reversedChain)
        let password = shaData!.map { String(format: "%02hhx", $0) }.joined()
        print("Password SHA-256: \(password)")
        // End of password generation!
        
        return password
    }
    
    static func sha256(string: String) -> Data? {
        guard let messageData = string.data(using:String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }
}
