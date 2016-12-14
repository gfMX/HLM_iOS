//
//  Helper.swift
//  HotLikeMe
//
//  Created by developer on 17/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import Foundation
import RNCryptor
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
    /***************************************************************************
                                Encryption Zone
     ***************************************************************************/
    
    // MARK: Encryption
    static func encryptString(text: String, password: String) -> String {
        let nsString = text as NSString
        let data:Data = nsString.data(using: String.Encoding.utf8.rawValue)!
        let ciphertext = RNCryptor.encrypt(data: data, withPassword: password)
        let cipherString = ciphertext.base64EncodedString()
        
        print("Encrypted Text: \(cipherString)")
        
        return cipherString
    }
    
    static func decryptString(text: String, password: String) -> String {
        let string64 = text.data(using: String.Encoding.utf8)
        let result64Data = Data(base64Encoded: string64!, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
        
        do {
            let originalData = try RNCryptor.decrypt(data: result64Data/*.data(using: String.Encoding.utf8)!*/, withPassword: password)
            let decryptedString = NSString(data: originalData, encoding: String.Encoding.utf8.rawValue) as! String
            print("Decrypted data: \(decryptedString)")
            
            return decryptedString
        } catch {
            print(error)
            return "Text could not be decrypted"
        }
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
    /***************************************************************************
                            End of Encryption Zone
     ***************************************************************************/
}
