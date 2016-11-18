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
}
