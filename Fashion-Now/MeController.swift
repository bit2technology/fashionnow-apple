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
    /// Get currect poll
    private func poll(index: Int) -> ParsePoll {
        if index < postedPolls.count {
            return postedPolls[index]
        }
        return myPolls[index - postedPolls.count]!
    }

    private var scaledImages = [String: UIImage]()

    weak var refreshControl: UIRefreshControl!

    weak var header: MePollHeader?
    weak var footer: MePollFooter?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Basic configuration
        navigationController!.tabBarItem.selectedImage = UIImage(named: "TabBarIconProfileSelected")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Bordered, target: nil, action: nil)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
        notificationCenter.addObserver(self, selector: "pollDeleted:", name: FNPollDeletedNotificationName, object: nil)
        notificationCenter.addObserver(self, selector: "pollPosted:", name: FNPollPostedNotificationName, object: nil)

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
        PFAnalytics.fn_trackScreenShowInBackground("Me: Main", block: nil)
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
            else if showError && error != nil && (error.domain != FNErrorDomain || error.code == FNErrorCode.ConnectionLost.rawValue) {
                FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
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
                // Get appropriate cell
                var poll: ParsePoll!
                if idx < postedPolls.count {
                    poll = postedPolls[idx]
                } else {
                    poll = myPolls[idx - postedPolls.count]
                }
                (segue.destinationViewController as ResultPollController).poll = poll
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
            if let index = myPolls.removePoll(removedPoll) {
                removedPoll.unpinInBackgroundWithBlock(nil)
                collectionView?.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
            }
        }
    }

    func pollPosted(notification: NSNotification) {
        if let postedPoll = notification.userInfo?["poll"] as? ParsePoll {
            postedPolls.insert(postedPoll, atIndex: 0)
            collectionView?.reloadData()
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

        // Get cell
        let cell = (collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as MePollCell)

        // Set urls to check later if it is still the same cell
        let poll = self.poll(indexPath.row)
        cell.leftImageUrl = poll.photos?[0].image?.url
        cell.rightImageUrl = poll.photos?[1].image?.url

        if cell.leftImageUrl != nil && cell.rightImageUrl != nil {

            // If both images are already cached, just set them and return the cell
            cell.leftImageView.image = scaledImages[cell.leftImageUrl!]
            cell.rightImageView.image = scaledImages[cell.rightImageUrl!]
            if cell.leftImageView.image != nil && cell.rightImageView.image != nil {
                // Adjust aspect ratio
                cell.leftImageView.fn_setAspectRatio(nil)
                cell.rightImageView.fn_setAspectRatio(nil)
                // Remove loading if still exists
                if let indicator = cell.subviews.last as? UIActivityIndicatorView {
                    indicator.removeFromSuperview()
                }
                return cell
            }

            // Show loading interface
            var activityIndicator: UIActivityIndicatorView!
            if let indicator = cell.subviews.last as? UIActivityIndicatorView {
                indicator.hidden = false
                indicator.startAnimating()
                activityIndicator = indicator
            } else {
                activityIndicator = cell.fn_setLoading(style: .White, background: UIColor.fn_lighter(alpha: 1))
            }

            let completion: SDWebImageCompletionWithFinishedBlock = { (image, error, cacheType, completed, url) -> Void in
                let urlString = url.absoluteString!

                // Downsacle image in background if necessary
                var scaledImage = image
                if scaledImage != nil {

                    var itemSize = (self.collectionViewLayout as UICollectionViewFlowLayout).itemSize

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in

                        scaledImage = image.fn_resized(itemSize.height)

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.scaledImages[urlString] = scaledImage

                            var imageView: UIImageView!
                            if urlString == cell.leftImageUrl {
                                imageView = cell.leftImageView
                            } else if urlString == cell.rightImageUrl {
                                imageView = cell.rightImageView
                            } else {
                                // Too late. Cell is already being used by another item. Just do nothing.
                                return
                            }

                            imageView.image = scaledImage
                            imageView.fn_setAspectRatio(scaledImage)

                            // Remove loading interface
                            if cell.leftImageView.image != nil && cell.rightImageView.image != nil {
                                if let indicator = cell.subviews.last as? UIActivityIndicatorView {
                                    UIView.animateWithDuration(0.15, animations: { () -> Void in
                                        indicator.alpha = 0
                                    }, completion: { (completed) -> Void in
                                        indicator.removeFromSuperview()
                                    })
                                }
                            }
                        })
                    })
                } else {
                    // TODO: Better error handling
                    NSLog("MePollCell image download error: \(error)")
                    return
                }
            }

            let manager = SDWebImageManager.sharedManager()
            manager.downloadImageWithURL(NSURL(string: cell.leftImageUrl!), options: nil, progress: nil, completed: completion)
            manager.downloadImageWithURL(NSURL(string: cell.rightImageUrl!), options: nil, progress: nil, completed: completion)
        }
        else {
            // TODO: Better error handling
            NSLog("MePollCell image download error: not enough URLs")
        }

        return cell
    }
}

class MePollCell: UICollectionViewCell {

    @IBOutlet weak var leftImageView, rightImageView: UIImageView!
    private var containers: [UIView] {
        return [leftImageView.superview!, rightImageView.superview!]
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        fn_applyPollMask(containers.first!, containers.last!)

        let pollContainerLayer = leftImageView.superview!.superview!.layer
        pollContainerLayer.rasterizationScale = UIScreen.mainScreen().scale
        pollContainerLayer.shouldRasterize = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        for container in containers {
            container.layer.mask.transform = CATransform3DMakeScale(container.bounds.width, container.bounds.height, 1)
        }
        CATransaction.commit()
    }

    var leftImageUrl: String?
    var rightImageUrl: String?
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
            avatarImageView.setImageWithURL(currentUserUrl, placeholderImage: UIColor.fn_placeholder().fn_image(), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
        nameLabel.text = currentUser.name

        return self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.image = UIColor.fn_placeholder().fn_image()
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

