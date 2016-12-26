//
//  UploadImageCollectionViewController.swift
//  HotLikeMe
//
//  Created by developer on 22/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Firebase

private let reuseIdentifier = "cellView"

class UploadImageCollectionViewController: UICollectionViewController {
    
    let imageLimit = 120
    var timer: Timer!
    var nsImageId:NSArray = []
    var nsImageData:NSArray = []
    var indexOfSelectedImages = [IndexPath]()
    var imageReference = [String]()
    
    var imTinyUrl = [String]()
    var imFullUrl = [String]()
    
    var imThumbSelected = [String]()
    var imImageSelected = [String]()
    
    var imageCount: Int!
    
    var firebaseReference: FIRDatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearVars()
        firebaseReference = FireConnection.databaseReference.child("users").child(FireConnection.fireUser.uid)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        self.collectionView?.allowsMultipleSelection = true
        getFbPhotos()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    
    }


    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.nsImageData.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbCollectionViewCell
    
        // Configure the cell
    
    
        Helper.loadImageFromUrl(url: nsImageData[indexPath.item] as! String, view: cell.imageView)
        cell.imageView.contentMode = UIViewContentMode.scaleAspectFill;
        cell.layer.cornerRadius = 8
        
        if indexOfSelectedImages.contains(indexPath){
            cell.layer.borderColor = UIColor.gray.cgColor
            cell.layer.borderWidth = 5
            
            imImageSelected.append(imFullUrl[indexPath.item])
            imThumbSelected.append(imTinyUrl[indexPath.item])
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 0
            
            if imImageSelected.contains(imFullUrl[indexPath.item]){
                imImageSelected.remove(at: imImageSelected.index(of: imFullUrl[indexPath.item])!)
            }
            if imThumbSelected.contains(imTinyUrl[indexPath.item]){
                imThumbSelected.remove(at: imThumbSelected.index(of: imTinyUrl[indexPath.item])!)
            }
        }
        
        //print("Images: ", imImageSelected)
        //print("Thumbs: ", imThumbSelected)
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.lightGray.cgColor
        cell?.layer.borderWidth = 5
        
        return true
    }
    */
   /*
    // change background color when user touches cell
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.magenta.cgColor
        cell?.layer.borderWidth = 5
    }
    
    // change background color back when user releases touch
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = nil
        cell?.layer.borderWidth = 0
    }
    */
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print(nsImageId[indexPath.item])
        
        if !indexOfSelectedImages.contains(indexPath){
            indexOfSelectedImages.append(indexPath)
        } else {
            indexOfSelectedImages.remove(at: indexOfSelectedImages.index(of: indexPath)!)
        }
        if !imageReference.contains(nsImageId[indexPath.item] as! String) {
            imageReference.append(nsImageId[indexPath.item] as! String)
        } else {
            imageReference.remove(at: imageReference.index(of: nsImageId[indexPath.item] as! String)!)
        }
        
        print("Index: " + indexOfSelectedImages.description)
        print("Ids: " + imageReference.description)
        
        //self.collectionView?.reloadItems(at: [indexPath])
        
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //let cell = collectionView.cellForItem(at: indexPath)

        self.collectionView?.reloadItems(at: [indexPath])
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        //let cell = collectionView.cellForItem(at: indexPath)

        self.collectionView?.reloadItems(at: [indexPath])
    }
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    // MARK: Actions
    
    func getFbPhotos(){
        
        let graphRequest: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/photos", parameters:["fields": "picture, images", "limit": "\(imageLimit)"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            if error != nil {
                //handle error
                print("❌ graphrequest error")
                self.view.makeToast("Please Log In to Facebook Again to Upload Pictures", duration: 5.0, position: .center)
            } else {
                //print(result ?? "Failed to get result")
                let nsResult = result as! NSDictionary
                let nsData = nsResult.value(forKey: "data") as! NSArray
                self.nsImageId = nsData.value(forKey: "id") as! NSArray
                self.nsImageData = nsData.value(forKey: "picture") as! NSArray
                
                for i in 0 ..< self.nsImageData.count {
                    let object0 = nsData[i] as! NSDictionary
                    let object1 = object0.value(forKey: "images") as! NSArray
                    let object2 = object1[0] as! NSDictionary
                    
                    self.imFullUrl.append(object2.value(forKey: "source") as! String)
                    self.imTinyUrl.append(self.nsImageData[i] as! String)
                    
                    //print("Tinys: ", self.nsImageData[i])
                    //print("Testing: ", object1[0])
                }
                self.collectionView?.reloadData()
            }
        })
        
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadData(start: Int, total: Int) {
        let uniqueId = NSUUID().uuidString
        let urlImage = URL(string: imImageSelected[start])
        let urlThumb = URL(string: imThumbSelected[start])
        var currentImage = start
        
        print("Current item: " + currentImage.description, " Total images: " + total.description)
        
        let metadataInfo = FIRStorageMetadata()
        metadataInfo.contentType = "image/jpeg"
        
        print("UUID: ", uniqueId)
        print("Download Started")
        getDataFromUrl(url: urlImage!) { (data, response, error)  in
            guard let data = data, error == nil else { return }
            print("Download Finished")
            DispatchQueue.main.async() { () -> Void in
                
                let imageName = "image_" + uniqueId + ".jpg"
                print("Image name: ", imageName)
                
                let fullImageRef = FireConnection.storageReference.child(FireConnection.fireUser.uid).child("images").child(imageName)
                let uploadTask = fullImageRef.put(data, metadata: metadataInfo) { metadata, error in
                    if (error != nil) {
                        // Uh-oh, an error occurred!
                    } else {
                        
                        let downloadURL = metadata!.downloadURL
                        print("Upload Image Finished: ", downloadURL)
                        
                        self.getDataFromUrl(url: urlThumb!) { (data, response, error)  in
                            guard let data = data, error == nil else { return }
                            print("Download Finished")
                            DispatchQueue.main.async() { () -> Void in
                        
                                let thumbName = "thumb_" + uniqueId + ".jpg"
                                print("Image name: ", thumbName)
                        
                                let thumbImageRef = FireConnection.storageReference.child(FireConnection.fireUser.uid).child("images").child("thumbs").child(thumbName)
                                let uploadTiny = thumbImageRef.put(data, metadata: metadataInfo) { metadata, error in
                                    if (error != nil) {
                                        // Uh-oh, an error occurred!
                                    } else {
                                
                                        let downloadURL = metadata!.downloadURL
                                        print("Upload Thumb Finished: ", downloadURL)
                                        
                                        let thumbPath = "/" + FireConnection.fireUser.uid + "/images/thumbs/" + thumbName
                                        let imagePath = "/" + FireConnection.fireUser.uid + "/images/" + imageName
                                        
                                        self.firebaseReference.child("images").child(uniqueId).setValue(imagePath)
                                        self.firebaseReference.child("thumbs").child(uniqueId).setValue(thumbPath)
                                        
                                        if start < total - 1 {
                                            currentImage = +1
                                            print("Uploading Image: ", currentImage)
                                            self.downloadData(start: currentImage, total: total)
                                        }
                                
                                    }
                                }
                                uploadTiny.resume()
                            }
                        }
                        
                    }
                }
                uploadTask.resume()
            }
        }
        
    }
    
    func clearVars(){
        imImageSelected.removeAll()
        imThumbSelected.removeAll()
    }
    
    @IBAction func uploadImages(_ sender: UIBarButtonItem) {
        print("Preparing images for upload")
        let countImages = imImageSelected.count
        print("Image upload count: ", countImages)
        
        if countImages > 0 {
            downloadData(start: 0, total: countImages)
        } else {
            print ("No images selected")
        }
    }

}
