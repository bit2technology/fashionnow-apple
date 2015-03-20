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

    private var scaledImages = [String: UIImage]()

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

        // Get appropriate cell
        var poll: ParsePoll!
        if indexPath.item < postedPolls.count {
            poll = postedPolls[indexPath.item]
        } else {
            poll = myPolls[indexPath.item - postedPolls.count]
        }

        // Get cell
        let cell = (collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as MePollCell)

        // Hide poll images
        let container = cell.pollContainer
        container.hidden = true

        // Set urls to check later if it is still the same cell
        cell.leftImageUrl = poll?.photos?.first?.image?.url
        cell.rightImageUrl = poll?.photos?.last?.image?.url

        if cell.leftImageUrl != nil && cell.rightImageUrl != nil {

            // If both images are already cached, just set them and return the cell
            cell.leftImageView.image = scaledImages[cell.leftImageUrl!]
            cell.rightImageView.image = scaledImages[cell.rightImageUrl!]
            if cell.leftImageView.image != nil && cell.rightImageView.image != nil {
                container.hidden = false
                return cell
            }

            // Show loading interface
            cell.activityIndicator.startAnimating()

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

                            if urlString == cell.leftImageUrl {
                                cell.leftImageView.image = scaledImage
                            } else if urlString == cell.rightImageUrl {
                                cell.rightImageView.image = scaledImage
                            } else {
                                // Too late. Cell is already being used by another item. Just do nothing.
                                return
                            }

                            if cell.leftImageView.image != nil && cell.rightImageView.image != nil {
                                container.hidden = false
                                cell.activityIndicator.stopAnimating()
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

