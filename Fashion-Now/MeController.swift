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
    private var myPollsQuery: PFQuery! {
        get {
            let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
            .includeKey(ParsePollPhotosKey)
            .whereKey(ParsePollCreatedByKey, equalTo: ParseUser.currentUser())
            .orderByDescending(ParseObjectCreatedAtKey)
            myPollsQuery.limit = ParseQueryLimit
            return myPollsQuery
        }
    }

    weak var activityIndicator: UIActivityIndicatorView!
    weak var refreshControl: UIRefreshControl!
    var isBeingUpdated = false

    var header: MeHeaderView?

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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Layout configuration
        let itemWidth = floor(((collectionView?.bounds.width ?? 320) - 8) / 3)
        (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: itemWidth, height: floor(itemWidth * 3 / 2))

        // Update header information
        header?.prepare()
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
            loadRemotePolls()
        } else {
            sender.endRefreshing()
        }
    }

    private func loadPolls() {

        // If it is disconnected, show cached polls
        if InternetIsOnline() {
            loadRemotePolls()
        }
        else {
            isBeingUpdated = true
            myPollsQuery.fromLocalDatastore()
            .findObjectsInBackgroundWithBlock { (objects, error) -> Void in

                NSLog("objects \(objects) error \(error)")

                self.isBeingUpdated = false
                self.activityIndicator.stopAnimating()

                self.myPolls = (objects ?? []) as [ParsePoll]
                self.collectionView?.reloadData()
            }
        }
    }

    private func loadRemotePolls() {

        if !InternetIsOnline() {
            activityIndicator.stopAnimating()
            refreshControl.endRefreshing()
            isBeingUpdated = false

            Toast.show(text: NSLocalizedString("ME_LOAD_POLLS_OFFLINE_MESSAGE", value: "No internet connection", comment: "Message for when user has no connection to download new polls"), type: .Error)
            return
        }

        isBeingUpdated = true

        myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            self.isBeingUpdated = false

            if error != nil {
                Toast.show(text: NSLocalizedString("ME_LOAD_POLLS_FAIL_MESSAGE", value: "Error downloading polls", comment: "Message for when user fail to download new polls"), type: .Error)
                return
            }

            if let unwrappedObjects = objects as? [ParsePoll] {
                PFObject.pinAllInBackground(unwrappedObjects, block: nil)
                self.myPolls = unwrappedObjects
                self.collectionView?.reloadData()
            }
        }
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
        header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Me Overview", forIndexPath: indexPath) as MeHeaderView
        return header!.prepare()
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

    @IBOutlet weak var avatarImageView: UIImageView!
    var avatarUrl: NSURL?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editProfileButton: UIButton!

    func prepare() -> Self {
        let currentUser = ParseUser.currentUser()

        let currentUserUrl = currentUser.avatarURL(size: 84)
        if avatarUrl != currentUserUrl {
            avatarUrl = currentUserUrl
            avatarImageView.setImageWithURL(currentUserUrl, placeholderImage: UIColor.defaultPlaceholderColor().image(), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
        nameLabel.text = currentUser.name

        return self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.image = UIColor.defaultPlaceholderColor().image()
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.layer.masksToBounds = true
    }

}

class PollCell: UICollectionViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
}