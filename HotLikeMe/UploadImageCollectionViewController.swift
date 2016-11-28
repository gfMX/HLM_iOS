//
//  UploadImageCollectionViewController.swift
//  HotLikeMe
//
//  Created by developer on 22/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import FBSDKCoreKit

private let reuseIdentifier = "cellView"

class UploadImageCollectionViewController: UICollectionViewController {
    
    let imageLimit = 120
    var nsImageId:NSArray = []
    var nsImageData:NSArray = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.nsImageData.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbCollectionViewCell
    
        // Configure the cell
    
    
        Helper.loadImageFromUrl(url: nsImageData[indexPath.item] as! String, view: cell.imageView)
        cell.imageView.contentMode = UIViewContentMode.scaleAspectFill;
        //cell.backgroundColor = UIColor.cyan
        //cell.layer.borderColor = UIColor.lightGray.cgColor
        //cell.layer.borderWidth = 3
        cell.layer.cornerRadius = 8
    
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
    
    /*// change background color when user touches cell
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.lightGray.cgColor
        cell?.layer.borderWidth = 5
    }*/
    
    /*// change background color back when user releases touch
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = nil
        cell?.layer.borderWidth = 0
    } */

    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        print(nsImageId[indexPath.item])
        
        return true
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
                print("graphrequest error")
            } else {
                //print(result ?? "Failed to get result")
                let nsResult = result as! NSDictionary
                let nsData = nsResult.value(forKey: "data") as! NSArray
                self.nsImageId = nsData.value(forKey: "id") as! NSArray
                self.nsImageData = nsData.value(forKey: "picture") as! NSArray
                print("Thumbs")
                print("URLs: " + self.nsImageData.count.description + " IDs: " + self.nsImageId.count.description)
                
                self.collectionView?.reloadData()
            }
        })
        
    }
    
    @IBAction func goBack(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadImages(_ sender: UIBarButtonItem) {
        
    }

}
