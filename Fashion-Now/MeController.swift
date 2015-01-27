//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class MeController: UICollectionViewController {

    var myPolls: [ParsePoll]?

    weak var refreshControl: UIRefreshControl?
    var isBeingUpdated = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Basic configuration
        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconMeSelected")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

        // Activity indicator background view
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor.lightGrayColor()
        activityIndicator.startAnimating()
        collectionView?.backgroundView = activityIndicator

        // Load cached polls
        let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
        myPollsQuery.includeKey(ParsePollPhotosKey)
        myPollsQuery.whereKey(ParsePollCreatedByKey, equalTo: ParseUser.currentUser())
        myPollsQuery.orderByDescending(ParseObjectCreatedAtKey)
        myPollsQuery.limit = Int.max
        myPollsQuery.fromLocalDatastore()
        myPolls = myPollsQuery.findObjects() as? [ParsePoll]
        if myPolls?.count > 0 {
            activityIndicator.stopAnimating()
        }

        // Configure refresh control for manual update
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "updatePollList", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        self.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = ParseUser.currentUser().name

        updatePollList()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func loginChanged(notification: NSNotification) {

        myPolls = nil
        PFObject.unpinAllObjects()
        (collectionView?.backgroundView as UIActivityIndicatorView).startAnimating()
        collectionView?.reloadData()

        updatePollList()
    }

    func updatePollList() {

        if isBeingUpdated {
            return
        }

        isBeingUpdated = true

        let currentUser = ParseUser.currentUser()
        if PFAnonymousUtils.isLinkedWithUser(currentUser) {
            (collectionView?.backgroundView as UIActivityIndicatorView).stopAnimating()
            refreshControl?.endRefreshing()
            return
        }

        let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
        myPollsQuery.includeKey(ParsePollPhotosKey)
        myPollsQuery.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
        myPollsQuery.orderByDescending(ParseObjectCreatedAtKey)
        myPollsQuery.limit = Int.max
        myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            // TODO: Error

            PFObject.pinAllInBackground(objects) { (success, error) -> Void in
                if error != nil {
                    NSLog("Pin error: \(error)")
                }
            }

            if objects.count > 0 {

                var newMyPolls = objects as? [ParsePoll]
                newMyPolls?.extend(self.myPolls ?? [])

                self.myPolls = newMyPolls
            }

            var addedIndexPaths = [NSIndexPath]()
            for 0 ..< objects.count {

            }
            self.collectionView?.insertItemsAtIndexPaths(<#indexPaths: [AnyObject]#>)

            (self.collectionView?.backgroundView as UIActivityIndicatorView).stopAnimating()
            self.refreshControl?.endRefreshing()
            self.isBeingUpdated = false
        }
    }

    @IBAction func logOutButtonPressed(snder: AnyObject) {
        ParseUser.logOut()
        NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
        tabBarController!.selectedIndex = 0
    }

    override func needsLogin() -> Bool {
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let unwrappedId = segue.identifier {

            switch unwrappedId {
            case "Result Controller":
                let idx = collectionView!.indexPathForCell(sender as UICollectionViewCell)!.item
                (segue.destinationViewController as ResultPollController).poll = myPolls![idx]
            default:
                return
            }
        }
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myPolls?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as PollCell

        let currentPoll = myPolls![indexPath.item]
        let leftImageUrl = currentPoll.photos?.first?.image?.url
        let rightImageUrl = currentPoll.photos?.last?.image?.url

        if leftImageUrl == nil || rightImageUrl == nil {
            return cell
        }

        cell.leftImageView.setImageWithURL(NSURL(string: leftImageUrl!), placeholderImage: nil, completed: { (image, error, cache, url) -> Void in
            // Completion
        }, usingActivityIndicatorStyle: .Gray)
        cell.rightImageView.setImageWithURL(NSURL(string: rightImageUrl!), placeholderImage: nil, completed: { (image, error, cache, url) -> Void in
            // Completion
        }, usingActivityIndicatorStyle: .Gray)

        return cell
    }
}

class PollCell: UICollectionViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
}