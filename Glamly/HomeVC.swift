//
//  HomeVC.swift
//  Glamly
//
//  Created by Kevin Grozav on 5/23/16.
//  Copyright © 2016 UCSD. All rights reserved.
//

import UIKit
import Parse



class HomeVC: UICollectionViewController {

    
    var refresher : UIRefreshControl!
    //size of page
    var page : Int = 10
    var uuidArray = [String]()
    var picArray = [PFFile]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .whiteColor()
        self.navigationItem.title = PFUser.currentUser()?.username
        
        //pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        collectionView?.addSubview(refresher)
        
        //revceive notification from editVC
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload:", name: "reload", object: nil)
        
        
        loadPosts()
    }
    
    //refreshing function
    func refresh(){
        collectionView?.reloadData()
    
        refresher.endRefreshing()
    }
    
    
    //reloading function
    func reload(notification:NSNotification){
        collectionView?.reloadData()
    }
    
    
    func loadPosts(){
        let query = PFQuery(className: "posts")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.limit = page
        query.findObjectsInBackgroundWithBlock ({ (objects: [PFObject]?, error : NSError?)-> Void in
            if error == nil {
                //clean up
                self.uuidArray.removeAll(keepCapacity: false)
                self.picArray.removeAll(keepCapacity: false)
                
                //find objects related to our request
                for object in objects! {
                    //add found data to arrays (holders)
                    self.uuidArray.append(object.valueForKey("uuid") as! String)
                    self.picArray.append(object.valueForKey("pic") as! PFFile)
                }
                self.collectionView?.reloadData()
            }else{
                print(error!.localizedDescription)
            }
        })
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return picArray.count
    }
    
    //cell config
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)-> UICollectionViewCell {
        //define cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! pictureCell
        //get picture from the picArray
        picArray[indexPath.row].getDataInBackgroundWithBlock ({ (data:NSData?, error:NSError?)-> Void in
            if error == nil {
                cell.picImg.image = UIImage(data:data!)
            }
        })
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", forIndexPath: indexPath) as! HeaderView
        
        
        header.fullnameLbl.text = (PFUser.currentUser()!.objectForKey("username") as? String)?.uppercaseString
        //header.fullnameLbl.text = PFUser.currentUser()?.username
        header.descriptionLbl.text = ""
        
        let avaQuery = PFUser.currentUser()?.objectForKey("image") as! PFFile
        avaQuery.getDataInBackgroundWithBlock { (data:NSData?, error: NSError?) in
            if error == nil {
                header.avaImg.image = UIImage(data: data!)
                
            }
        }
        
        header.editProfileBtn.setTitle("edit profile", forState: .Normal)
        
        //count total posts
        let posts = PFQuery(className: "posts")
        posts.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        posts.countObjectsInBackgroundWithBlock( { (count: Int32, error:NSError?) ->Void in
            if error == nil{
                header.posts.text = "\(count)"
            }
        })
        
        //count total followers
        let followers = PFQuery(className: "follow")
        followers.whereKey("follower", equalTo: PFUser.currentUser()!.username!)
        followers.countObjectsInBackgroundWithBlock( { (count: Int32, error:NSError?) ->Void in
            if error == nil{
                header.followers.text = "\(count)"
            }
        })
        
        
        //count total followings
        let followings = PFQuery(className: "follow")
        followings.whereKey("following", equalTo: PFUser.currentUser()!.username!)
        followings.countObjectsInBackgroundWithBlock( { (count: Int32, error:NSError?) ->Void in
            if error == nil{
                header.following.text = "\(count)"
            }
        })
        
        
        //Implement tap gestures
        //tap posts
        let postsTap = UITapGestureRecognizer(target: self, action: "postsTap")
        postsTap.numberOfTapsRequired = 1
        header.posts.userInteractionEnabled = true
        header.posts.addGestureRecognizer(postsTap)
        
        //tap followers
        let followersTap = UITapGestureRecognizer(target: self, action: "followersTap")
        followersTap.numberOfTapsRequired = 1
        header.followers.userInteractionEnabled = true
        header.followers.addGestureRecognizer(followersTap)
        
        //tap followings
        let followingsTap = UITapGestureRecognizer(target: self, action: "followingsTap")
        followingsTap.numberOfTapsRequired = 1
        header.following.userInteractionEnabled = true
        header.following.addGestureRecognizer(followingsTap)
        
        
        return header
        
    }
    
    //taped posts label
    func postsTap(){
        if !picArray.isEmpty{
            let index = NSIndexPath(forItem: 0, inSection: 0)
            self.collectionView?.scrollToItemAtIndexPath(index, atScrollPosition: UICollectionViewScrollPosition.Top, animated: true)
        }
    }
    
    //tapped followers label
    func followersTap (){
        user = PFUser.currentUser()!.username!
        show = "followings"
        
        let followers = self.storyboard?.instantiateViewControllerWithIdentifier("followersVC") as! followersVC
        
        self.navigationController?.pushViewController(followers, animated: true)
    }
    
    //tapped followings label
    func followingsTap(){
        user = PFUser.currentUser()!.username!
        show = "followers"
        
        let followings = self.storyboard?.instantiateViewControllerWithIdentifier("followersVC") as! followersVC
        
        self.navigationController?.pushViewController(followings, animated: true)
        
    }
    /*override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }*/



    /*override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    
        // Configure the cell
    
        return cell
    }*/

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
