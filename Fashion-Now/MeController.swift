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

    private var myPolls = ParsePollList(type: .Mine)

    weak var refreshControl: UIRefreshControl!

    weak var header: MeReusableView?
    weak var footer: MeReusableView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Basic configuration
        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconMeSelected")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

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
        header?.prepareHeader()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Me: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func refreshControlDidChangeValue(sender: UIRefreshControl) {
        loadPolls()
    }

    private func loadPolls() {

        myPolls.update(type: .Newer) { (succeeded, error) -> Void in

            if succeeded {
                self.collectionView?.reloadData()
            }

            if error != nil {
                NSLog("Error: \(error)")
            }

            self.refreshControl.endRefreshing()
            self.footer?.activityIndicator?.startAnimating()
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


















    

    func loginChanged(notification: NSNotification) {

        // Clean caches. Also load polls if new user is not anonymous
        PFObject.unpinAllObjectsInBackgroundWithBlock(nil)
        myPolls.clear()
        collectionView?.reloadData()
        if !PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) {
            footer?.activityIndicator?.startAnimating()
            loadPolls()
        }
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Me Overview", forIndexPath: indexPath) as MeReusableView
            return header!.prepareHeader()
        }

        footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Loading Footer", forIndexPath: indexPath) as MeReusableView

       myPolls.update(type: .Older) { (succeeded, error) -> Void in

            if succeeded {
                self.collectionView?.reloadData()
            }

            if error != nil {
                NSLog("Error: \(error)")
            }

            self.refreshControl.endRefreshing()
            self.footer?.activityIndicator?.startAnimating()
        }
        return footer!
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as PollCell

        let currentPoll = myPolls[indexPath.item]
        let leftImageUrl = currentPoll?.photos?.first?.image?.url
        let rightImageUrl = currentPoll?.photos?.last?.image?.url

        if leftImageUrl == nil || rightImageUrl == nil {
            // TODO: Empty cell
            return cell
        }

        cell.leftImageView.setImageWithURL(NSURL(string: leftImageUrl!), placeholderImage: nil, completed: nil, usingActivityIndicatorStyle: .Gray)
        cell.rightImageView.setImageWithURL(NSURL(string: rightImageUrl!), placeholderImage: nil, completed: nil, usingActivityIndicatorStyle: .Gray)

        return cell
    }
}

class MeReusableView: UICollectionReusableView {

    @IBOutlet weak var avatarImageView: UIImageView?
    var avatarUrl: NSURL?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var editProfileButton: UIButton?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?

    func prepareHeader() -> Self {
        let currentUser = ParseUser.currentUser()

        let currentUserUrl = currentUser.avatarURL(size: 84)
        if avatarUrl != currentUserUrl {
            avatarUrl = currentUserUrl
            avatarImageView?.setImageWithURL(currentUserUrl, placeholderImage: UIColor.defaultPlaceholderColor().image(), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
        nameLabel?.text = currentUser.name

        return self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView?.image = UIColor.defaultPlaceholderColor().image()
        avatarImageView?.layer.cornerRadius = 42
        avatarImageView?.layer.masksToBounds = true
    }

}

class PollCell: UICollectionViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
}