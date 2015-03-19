//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class MeController: UICollectionViewController {

    /// Main list of polls to show
    private var myPolls = ParsePollList(type: .Mine)
    /// List of posted polls before update
    private var postedPolls = [ParsePoll]()

    weak var refreshControl: UIRefreshControl!

    weak var header: MePollHeader?
    weak var footer: MePollFooter?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Basic configuration
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Bordered, target: nil, action: nil)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
        notificationCenter.addObserver(self, selector: "pollDeleted:", name: PollDeletedNotificationName, object: nil)

        // Configure refresh control for manual update
        let refreshControl = UIRefreshControl()
        refreshControl.layer.zPosition = -9999
        refreshControl.addTarget(self, action: "refreshControlDidChangeValue:", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        self.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true

        // Set collection view item size
        let itemWidth = floor(((collectionView?.bounds.width ?? 320) - 8) / 3)
        (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: itemWidth, height: floor(itemWidth * 3 / 2))

        loadPolls(showError: false)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Update header information
        header?.updateContent()
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

    // Tries to update poll list
    private func loadPolls(type: ParsePollList.UpdateType = .Newer, showError: Bool = true) {
        myPolls.update(type: type, completionHandler: { (succeeded, error) -> Void in

            // If there is new polls, clean list of posted polls (since they will be in the update) and refresh content
            if succeeded {
                self.postedPolls = []
                self.collectionView?.reloadData()
            }
            // Show error if necessary
            else if showError && error != nil && (error.domain != AppErrorDomain || error.code == AppErrorCode.ConnectionLost.rawValue) {
                Toast.show(text: fn_localizedOfflineErrorDescription, type: .Error)
            }

            self.refreshControl.endRefreshing()
            self.footer?.prepare(updating: false)
        })
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

    func loginChanged(notification: NSNotification) {

        // Clean caches. Also load polls if new user is not anonymous
        myPolls = ParsePollList(type: .Mine)
        collectionView?.reloadData()
        if !PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) {
            footer?.activityIndicator?.startAnimating()
            loadPolls()
        }
    }

    func pollDeleted(notification: NSNotification) {
        if let removedPoll = notification.userInfo?["poll"] as? ParsePoll {
            if myPolls.removePoll(removedPoll) {
                removedPoll.unpinInBackgroundWithBlock(nil)
                collectionView?.reloadData()
            }
        }
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postedPolls.count + myPolls.count
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        // Header
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Me Overview", forIndexPath: indexPath) as MePollHeader
            self.header = header
            return header.updateContent()
        }

        // Footer
        let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Loading Footer", forIndexPath: indexPath) as MePollFooter
        footer.controller = self
        self.footer = footer
        return footer.prepare(updating: myPolls.downloading)
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var poll: ParsePoll!
        if indexPath.item < postedPolls.count {
            poll = postedPolls[indexPath.item]
        } else {
            poll = myPolls[indexPath.item - postedPolls.count]
        }
        return (collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as MePollCell).withPoll(poll)
    }
}

class MePollCell: UICollectionViewCell {

    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var pollContainer: UIView {
        return leftImageView.superview!.superview!
    }

    private var firstLayout = true
    override func layoutSubviews() {
        super.layoutSubviews()

        if firstLayout {

            let layer = leftImageView.superview!.superview!.layer
            layer.rasterizationScale = UIScreen.mainScreen().scale
            layer.shouldRasterize = true

            let containers = [leftImageView.superview!, rightImageView.superview!]
            fn_applyPollMask(containers.first!, containers.last!)
            for container in containers {
                container.layer.mask.transform = CATransform3DMakeScale(container.bounds.width, container.bounds.height, 1)
            }

            firstLayout = false
        }
    }

    private var leftImageUrl: String?
    private var rightImageUrl: String?

    /// Prepares cell for poll and returns itself
    func withPoll(poll: ParsePoll?) -> Self {

        let container = pollContainer
        container.hidden = true

        activityIndicator.startAnimating()
        leftImageView.image = nil
        rightImageView.image = nil

        leftImageUrl = poll?.photos?.first?.image?.url
        rightImageUrl = poll?.photos?.last?.image?.url

        if leftImageUrl != nil && rightImageUrl != nil {

            let completion: SDWebImageCompletionWithFinishedBlock = { (image, error, cacheType, completed, url) -> Void in

                var imageView: UIImageView!
                let urlString = url.absoluteString
                if urlString == self.leftImageUrl {
                    imageView = self.leftImageView
                } else if urlString == self.rightImageUrl {
                    imageView = self.rightImageView
                } else {
                    // Too late. Cell is already being used by another item. Just do nothing.
                    return
                }

                if image == nil {
                    // TODO: Better error handling
                    NSLog("MePollCell image download error: \(error)")
                    return
                }

                // TODO: downscale
                imageView.image = image

                if self.leftImageView.image != nil && self.rightImageView.image != nil {
                    container.hidden = false
                    self.activityIndicator.stopAnimating()
                }
            }

            let manager = SDWebImageManager.sharedManager()
            manager.downloadImageWithURL(NSURL(string: leftImageUrl!), options: nil, progress: nil, completed: completion)
            manager.downloadImageWithURL(NSURL(string: rightImageUrl!), options: nil, progress: nil, completed: completion)
        }
        else {
            // TODO: Better error handling
            NSLog("MePollCell image download error: not enough URLs")
        }

        return self
    }
}

class MePollHeader: UICollectionReusableView {

    @IBOutlet weak var avatarImageView: UIImageView!
    var avatarUrl: NSURL?
    @IBOutlet weak var nameLabel: UILabel!

    func updateContent() -> Self {
        let currentUser = ParseUser.currentUser()

        let currentUserUrl = currentUser.avatarURL(size: 84)
        if avatarUrl != currentUserUrl {
            avatarUrl = currentUserUrl
            avatarImageView.setImageWithURL(currentUserUrl, placeholderImage: UIColor.fn_placeholderColor().fn_image(), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
        nameLabel.text = currentUser.name

        return self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.image = UIColor.fn_placeholderColor().fn_image()
    }
}

class MePollFooter: UICollectionReusableView {

    // Delegate
    weak var controller: MeController?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadButton: UIButton!

    func prepare(#updating: Bool) -> Self {
        if updating {
            activityIndicator.startAnimating()
            loadButton.hidden = true
        } else {
            activityIndicator.stopAnimating()
            loadButton.hidden = false
        }
        return self
    }

    @IBAction func loadButtonPressed(sender: UIButton) {

        prepare(updating: true)
        controller?.loadPolls(type: .Older)
    }
}

