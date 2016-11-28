//
//  SelectProfilePicCollectionViewController.swift
//  HotLikeMe
//
//  Created by developer on 23/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "cellFireView"

class SelectProfilePicCollectionViewController: UICollectionViewController {
    
    var thumbUrls = [String]()
    var imageUrls = [String]()
    var thumbsStorage = [String]()
    
    var imagesOnCollection = 0
    var currentPicStorage: String!
    var currentPicURL: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        getFirePics()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        return self.thumbUrls.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FireCollectionViewCell
    
        // Configure the cell
        if !thumbUrls[indexPath.item].contains(" "){
            Helper.loadImageFromUrl(url: thumbUrls[indexPath.item], view: cell.imageThumb)
        }
        cell.imageThumb.contentMode = UIViewContentMode.scaleAspectFill;
        cell.backgroundColor = UIColor.lightGray
        cell.layer.cornerRadius = 8
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print(indexPath.item)
        print(imageUrls[indexPath.item])
    
        currentPicStorage = thumbsStorage[indexPath.item]
        currentPicURL = imageUrls[indexPath.item]
        showImage(newUrl: currentPicURL)
        
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
    
    func getFirePics(){
        let userID = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference()
        
        self.thumbUrls.removeAll()
        self.imageUrls.removeAll()
        
        ref.child("users").child(userID!).child("thumbs").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            print (value ?? "No values found")
            self.thumbsStorage = value?.allKeys as! [String]
            //let username = value?["alias"] as! String
            print("Thumbs found: " + (self.thumbsStorage.count.description))
            //print(thumbsStorage)
            
            
            let nCount = self.thumbsStorage.count
            self.thumbUrls = [String](repeating: " ", count: nCount)
            self.imageUrls = [String](repeating: " ", count: nCount)
            
            print ("Size of Arrays: " + self.thumbUrls.count.description + " " + self.imageUrls.count.description)
            
            self.getFirePicsUrls(storage: self.thumbsStorage)
            //self.collectionView?.reloadData()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getFirePicsUrls(storage: Array<Any>){
        //var currentImage = imageCount
        print ("Storage count: " + storage.count.description)
        
        for i in 0 ..< storage.count {
            //print ("Query" + i.description)
            FireConnection.storageReference.child(FireConnection.fireUser.uid).child("/images/thumbs/thumb_" + (storage[i] as! String) + ".jpg").downloadURL { (URL, error) -> Void in
                if (error != nil) {
                    print ("An error ocurred!")
                } else {
                    self.thumbUrls[i] = (URL?.absoluteString)!
                    //print (i.description + ": " + (URL?.absoluteString)!)
                }
            }
                
            FireConnection.storageReference.child(FireConnection.fireUser.uid).child("/images/image_" + (storage[i] as! String) + ".jpg").downloadURL { (URL, error) -> Void in
                if (error != nil) {
                    print ("An error ocurred!")
                } else {
                    self.imageUrls[i] = (URL?.absoluteString)!
                    //self.collectionView?.reloadData()
                    //print (i.description + ": " + (URL?.absoluteString)!)
                    if i == (storage.count - 1) {
                        print("    Updating the view")
                        print("--------------------------")
                        self.collectionView?.reloadData()
                    }
                }
                
            }
        }
        
    }
    
    func showImage(newUrl: String){
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissImage(sender:)))
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 23
        
        let newImageView: UIImageView = UIImageView()
        newImageView.frame = self.view.frame
        //newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        
        Helper.loadImageFromUrl(url: newUrl, view: newImageView)
        blurEffectView.addSubview(newImageView)
        
        let btnOk: UIButton = UIButton(frame: CGRect(x: 10, y: (self.view.frame.height-70), width: 100, height: 50))
        btnOk.setTitle("OK", for: .normal)
        btnOk.addTarget(self, action: #selector(buttonActionUp), for: .touchUpInside)
        btnOk.tag = 1
        blurEffectView.addSubview(btnOk)
        
        let btnCancel: UIButton = UIButton(frame: CGRect(x: (self.view.frame.width-120), y: (self.view.frame.height-70), width: 100, height: 50))
        btnCancel.setTitle("Cancel", for: .normal)
        btnCancel.addTarget(self, action: #selector(buttonActionCancel), for: .touchUpInside)
        btnCancel.tag = 2
        blurEffectView.addSubview(btnCancel)
        
        self.view.addSubview(blurEffectView)
        
        blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func dismissImage(sender: UITapGestureRecognizer) {
        print("Image Dismissed!")
        sender.view?.removeFromSuperview()
    }
    
    func buttonActionUp(sender: UIButton){
        let fireRef = FireConnection.databaseReference
            .child("users")
            .child(FireConnection.fireUser.uid)
            .child("preferences")
        
        fireRef.child("profile_pic_url").setValue(currentPicURL)
        fireRef.child("profile_pic_storage").setValue(currentPicStorage)
        
        //Update Firebase Profile: DisplayName
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            let newURL = NSURL(string: currentPicURL) as URL?
            print("New URL for Profile Pic" + (newURL?.absoluteString)!)
            changeRequest.photoURL = newURL
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Display Picture couldn't be updated!")
                    print(error)
                } else {
                    print ("Display Picture Updated!")
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        
         self.view.viewWithTag(23)?.removeFromSuperview()
        
    }
    
    func buttonActionCancel(sender: UIButton){
        self.view.viewWithTag(23)?.removeFromSuperview()
    }

    @IBAction func goBack(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func deleteImage(_ sender: UIBarButtonItem) {
        
    }

}
