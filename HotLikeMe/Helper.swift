//
//  Helper.swift
//  HotLikeMe
//
//  Created by developer on 17/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import SystemConfiguration
import Foundation
import RNCryptor
import UIKit

class Helper{
    
    static func loadImageFromUrl(url: String, view: UIImageView, type: String){
        
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
                    if type == "circle"{
                        view.image = UIImage(data: data)?.circleMask
                    } else {
                        view.image = UIImage(data: data)
                    }
                })
            }
        }
        
        // Run task
        task.resume()
    }
    /***************************************************************************
                                   Encryption
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
            let originalData = try RNCryptor.decrypt(data: result64Data, withPassword: password)
            let decryptedString = NSString(data: originalData, encoding: String.Encoding.utf8.rawValue) as! String
            print("Decrypted data: \(decryptedString)")
            
            return decryptedString
        } catch {
            print(error)
            return "Text could not be decrypted"
        }
    }
    
    // MARK: Password generator:
    static func genPassword(keyString: String) -> String {
        let passwordChain = keyString.replacingOccurrences(of: "chat_", with: "")
        let reversedChain = String(passwordChain.characters.reversed())
        let shaData = Helper.sha256(string: reversedChain)
        let password = shaData!.map { String(format: "%02hhx", $0) }.joined()
        print("Password SHA-256: \(password)")
        
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

// MARK: Extensions

extension UIImage {
    var circleMask: UIImage {
        let square = size.width < size.height ? CGSize(width: size.width, height: size.width) : CGSize(width: size.height, height: size.height)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 10
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard()
    {
        view.endEditing(true)
    }
}

protocol Utilities {
    // Not sure of this...
}

extension NSObject:Utilities{
    
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
    
}

