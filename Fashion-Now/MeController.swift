//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

public let NewPollSavedNotificationName = "NewPollSavedNotification"

class MeController: UICollectionViewController {

    private var myPolls = [ParsePoll]()

//    weak var backgroundActivityIndicator: UIActivityIndicatorView!
//    weak var refreshControl: UIRefreshControl!
//    var isBeingUpdated = false

    override func viewDidLoad() {
        super.viewDidLoad()

        loadCachedPolls()

        // Basic configuration
        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconMeSelected")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

//        // Activity indicator background view
//        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
//        activityIndicator.color = UIColor.lightGrayColor()
//        activityIndicator.startAnimating()
//        collectionView?.backgroundView = activityIndicator
//        self.backgroundActivityIndicator = activityIndicator
//
//        // Configure refresh control for manual update
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: "updatePollList", forControlEvents: .ValueChanged)
//        collectionView?.addSubview(refreshControl)
//        self.refreshControl = refreshControl
//        collectionView?.alwaysBounceVertical = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = ParseUser.currentUser().name
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Me: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func loadCachedPolls() {
        let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
        myPollsQuery.includeKey(ParsePollPhotosKey)
        myPollsQuery.whereKey(ParsePollCreatedByKey, equalTo: ParseUser.currentUser())
        myPollsQuery.orderByDescending(ParseObjectCreatedAtKey)
        myPollsQuery.limit = Int.max
        myPollsQuery.fromLocalDatastore()
        myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            self.myPolls = (objects ?? []) as [ParsePoll]
            self.collectionView?.reloadData()
        }
    }

    func loginChanged(notification: NSNotification) {

        PFObject.unpinAll(myPolls)
//        backgroundActivityIndicator.startAnimating()
//        collectionView?.reloadData()

        // Load cached polls
        myPolls = []
        loadCachedPolls()

//        if myPolls.count > 0 {
//            backgroundActivityIndicator.stopAnimating()
//        }
    }

//    func updatePollList() {
//
//        if isBeingUpdated {
//            return
//        }
//
//        isBeingUpdated = true
//
//        let currentUser = ParseUser.currentUser()
//        if PFAnonymousUtils.isLinkedWithUser(currentUser) {
//            (collectionView?.backgroundView as UIActivityIndicatorView).stopAnimating()
//            refreshControl.endRefreshing()
//            return
//        }
//
//        let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
//        myPollsQuery.includeKey(ParsePollPhotosKey)
//        myPollsQuery.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
//        myPollsQuery.orderByDescending(ParseObjectCreatedAtKey)
//        myPollsQuery.limit = Int.max
//        myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
//
//            // TODO: Error
//            if error != nil {
//                return
//            }
//
//            var newPolls = [ParsePoll]()
//            if let firstMyPoll = self.myPolls.first {
//                for poll in objects as [ParsePoll] {
//                    if firstMyPoll.createdAt.compare(poll.createdAt) == NSComparisonResult.OrderedAscending {
//                        newPolls.append(poll)
//                    }
//                }
//            } else {
//                newPolls = objects as [ParsePoll]
//            }
//
//            PFObject.pinAllInBackground(newPolls) { (success, error) -> Void in
//                if error != nil {
//                    NSLog("Pin error: \(error)")
//                }
//            }
//
//            if newPolls.count > 0 {
//
//                var addedIndexPaths = [NSIndexPath]()
//                for index in 0 ..< newPolls.count {
//                    addedIndexPaths.append(NSIndexPath(forItem: index, inSection: 0))
//                }
//
//                newPolls.extend(self.myPolls ?? [])
//                self.myPolls = newPolls
//
//                self.collectionView?.insertItemsAtIndexPaths(addedIndexPaths)
//            }
//
//            self.backgroundActivityIndicator.stopAnimating()
//            self.refreshControl.endRefreshing()
//            self.isBeingUpdated = false
//        }
//    }

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
                let idx = (collectionView!.indexPathsForSelectedItems().first as NSIndexPath).item
                (segue.destinationViewController as ResultPollController).poll = myPolls[idx]
            default:
                return
            }
        }
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myPolls.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as PollCell

        let currentPoll = myPolls[indexPath.item]
        let leftImageUrl = currentPoll.photos?.first?.image?.url
        let rightImageUrl = currentPoll.photos?.last?.image?.url

        if leftImageUrl == nil || rightImageUrl == nil {
            // TODO: Empty cell
            return cell
        }

        cell.leftImageView.setImageWithURL(NSURL(string: leftImageUrl!), placeholderImage: nil, completed: nil, usingActivityIndicatorStyle: .Gray)
        cell.rightImageView.setImageWithURL(NSURL(string: rightImageUrl!), placeholderImage: nil, completed: nil, usingActivityIndicatorStyle: .Gray)

        return cell
    }
}

class PollCell: UICollectionViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
}