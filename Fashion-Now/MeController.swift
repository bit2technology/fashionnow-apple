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

    weak var activityIndicator: UIActivityIndicatorView!
    weak var refreshControl: UIRefreshControl!
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
        self.activityIndicator = activityIndicator

        // Configure refresh control for manual update
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlDidChangeValue:", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        self.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true

        loadPolls()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Me: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func refreshControlDidChangeValue(sender: UIRefreshControl) {

        if sender.refreshing && !isBeingUpdated {
            loadPolls()
        } else {
            sender.endRefreshing()
        }
    }

    private func loadPolls() {
        isBeingUpdated = true

        let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
        .includeKey(ParsePollPhotosKey)
        .whereKey(ParsePollCreatedByKey, equalTo: ParseUser.currentUser())
        .orderByDescending(ParseObjectCreatedAtKey)
        myPollsQuery.limit = ParseQueryLimit
        myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            if error == nil {
                self.processQueryResponse(objects, error: error)
            }
            // If myPolls is empty, get from pinned polls
            else if self.myPolls.count <= 0 {
                myPollsQuery.fromLocalDatastore()
                .findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                    self.processQueryResponse(objects, error: error)
                }
            }
        }
    }

    private func processQueryResponse(objects: [AnyObject]!, error: NSError!) {
        activityIndicator.stopAnimating()
        refreshControl.endRefreshing()
        isBeingUpdated = false

        myPolls = (objects ?? []) as [ParsePoll]
        PFObject.pinAllInBackground(myPolls, block: nil)
        collectionView?.reloadData()
    }

    func loginChanged(notification: NSNotification) {

        // Clean caches. Also load polls if new user is not anonymous
        PFObject.unpinAllObjectsInBackgroundWithBlock(nil)
        myPolls = []
        collectionView?.reloadData()
        if !PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) {
            activityIndicator.startAnimating()
            loadPolls()
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

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Me Overview", forIndexPath: indexPath) as UICollectionReusableView
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

class MeHeaderView: UICollectionReusableView {

    @IBOutlet weak var leftImageView: UIImageView!

}

class PollCell: UICollectionViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
}