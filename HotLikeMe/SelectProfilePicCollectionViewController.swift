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
    
        return self.thumbUrls.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FireCollectionViewCell
    
        // Configure the cell
        Helper.loadImageFromUrl(url: thumbUrls[indexPath.item], view: cell.imageThumb)
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
    
        showImage(newUrl: imageUrls[indexPath.item])
        
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
        
        ref.child("users").child(userID!).child("thumbs").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            print (value ?? "No values found")
            let thumbsStorage = value?.allKeys as! [String]
            //let username = value?["alias"] as! String
            print("Thumbs found: " + (thumbsStorage.count.description))
            //print(thumbsStorage)
            
            
            //let nCount = thumbsStorage.count
            //for _ in 0 ..< nCount {
                //self.thumbUrls = [String](repeating: " ", count: nCount) //.append("") //
                //self.imageUrls = [String](repeating: " ", count: nCount)
            //}
 
            
            self.getFirePicsUrls(storage: thumbsStorage)
            //self.collectionView?.reloadData()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getFirePicsUrls(storage: Array<Any>){
        print ("Storage count: " + storage.count.description)
        
        for i in 0 ..< storage.count{
            //print (storage[i] as! String)
            FireConnection.storageReference.child(FireConnection.fireUser.uid).child("/images/thumbs/thumb_" + (storage[i] as! String) + ".jpg").downloadURL { (URL, error) -> Void in
                if (error != nil) {
                    print ("An error ocurred!")
                } else {
                    // Get the download URL for 'images/stars.jpg'
                    self.thumbUrls.append((URL?.absoluteString)!) //.insert((URL?.absoluteString)!, at: i) //
                    //print (URL ?? "Not a valid URL was found")
                    
                }
                if i == (storage.count - 1) {
                    print("Updating the view")
                    self.collectionView?.reloadData()
                }
            }
            
            FireConnection.storageReference.child(FireConnection.fireUser.uid).child("/images/image_" + (storage[i] as! String) + ".jpg").downloadURL { (URL, error) -> Void in
                if (error != nil) {
                    print ("An error ocurred!")
                } else {
                    self.imageUrls.append((URL?.absoluteString)!) //.insert((URL?.absoluteString)!, at: i) //
                    //print (URL ?? "Not a valid URL was found")
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
        btnOk.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
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
    
    func buttonAction(sender: UIButton){
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
