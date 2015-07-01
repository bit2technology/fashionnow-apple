//
//  ProfileController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

// Action Sheet
private let asLogOut = NSLocalizedString("ProfileController.gearButton.actionSheet.logOutButtonTitle", value: "Log Out", comment: "Shown when user taps the gear button")
private let asLinkFB = NSLocalizedString("ProfileController.gearButton.actionSheet.linkFacebookButtonTitle", value: "Connect to Facebook", comment: "Shown when user taps the gear button")
private let asUnlinkFB = NSLocalizedString("ProfileController.gearButton.actionSheet.unlinkFacebookButtonTitle", value: "Disconnect of Facebook", comment: "Shown when user taps the gear button")
private let asEditAccount = NSLocalizedString("ProfileController.gearButton.actionSheet.editAccountkButtonTitle", value: "Edit Account", comment: "Shown when user taps the gear button")
private let asMap = NSLocalizedString("ProfileController.gearButton.actionSheet.mapButtonTitle", value: "Devices Map", comment: "Shown when user taps the gear button")

class ProfileController: FNCollectionController, UIActionSheetDelegate {

    /// User to present info from
    lazy var user = ParseUser.current()
    /// Main list of polls to show
    private var userPolls: ParsePollList!
    /// If count buttons are interactable
    private var countButtonsEnabled = true

    /// List of posted polls before update (only if user is me)
    private var postedPolls = [ParsePoll]()
    /// Get correct poll
    private func poll(index: Int) -> ParsePoll {
        if index < postedPolls.count {
            return postedPolls[index]
        }
        return userPolls[index - postedPolls.count]!
    }

    /// Cache for scaled down images
    private var scaledImages = [String: UIImage]()
    /// Custom Refresh Control
    private weak var refreshControl: UIRefreshControl!
    /// Reference to the Collection View Header
    private weak var header: ProfileHeader!
    /// Reference to the Collection View Footer
    private weak var footer: ProfileFooter!

    /// Updates Navigation Item and Collection View Header with user information.
    private func updateUserInfo() {
        navigationItem.title = user.displayName
        let userIsCurrent = (user == ParseUser.current())
        if !userIsCurrent {
            header?.editProfileButton.setTitle("Follow", forState: .Normal)
        }

        if let newUserAvatarURL = user.avatarURL(size: 88) where header != nil && newUserAvatarURL != header?.avatarImageView.sd_imageURL() {
            header?.avatarImageView.setImageWithURL(newUserAvatarURL, placeholderImage: UIImage(named: "PlaceholderUserBig"), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
    }


















    func friendsUpdated(sender: NSNotification?) {
        //let title = (sender?.userInfo?["error"] == nil ? "\(ParseFriendsList.shared.count)\n" : "") + "Friends"
        let title = "\(ParseFriendsList.shared.count)\nFriends"
        header?.friendsButton.setTitle(title, forState: .Normal)
    }



    func refreshControlDidChangeValue(sender: UIRefreshControl) {
        loadPolls()
        updateUserInfo()
    }

    @IBAction func loadPolls(sender: UIButton) {
        footer?.activityIndicator.hidden = false
        loadPolls()
    }









    @IBAction func headerBtnPressed(sender: UIButton) {

        let currentUser = ParseUser.current()

//        if user == currentUser {
            performSegueWithIdentifier("Edit Profile", sender: sender)
//        }
//        else if !currentUser.isLogged {
//            fn_tabBarController.presentLoginController()
//        }
//        else {
//            // TODO: Verify if this user is being followed
//            PFCloud.callFunctionInBackground("followUser", withParameters: ["follow": user.objectId!]) { (result, error) -> Void in
//                FNAnalytics.logError(error, location: "Profile: Follow User")
//            }
//        }
    }










    // Tries to update poll list
    private func loadPolls(type: ParsePollList.UpdateType = .Newer, showError: Bool = true) {

        userPolls.update(type: type, completionHandler: { (succeeded, error) -> Void in

            // If there is new polls, clean list of posted polls (since they will be in the update) and refresh content
            if succeeded {
                self.postedPolls = []
                self.collectionView?.reloadData()
            }
            // Show error if necessary
            else if showError, let error = error where (error.domain != FNErrorDomain || error.code == FNErrorCode.ConnectionLost.rawValue) {
                FNToast.show(title: FNLocalizedOfflineErrorDescription, type: .Error)
            }

            self.updateFooterButton()
            self.refreshControl.endRefreshing()
            self.footer?.activityIndicator.hidden = true
        })
    }

    private func updateFooterButton() {
        let hasPoll = collectionView!.numberOfItemsInSection(0) > 0
        footer?.loadButton.hidden = !hasPoll
        footer?.createBtn.hidden = hasPoll
    }

    @IBAction func creteFirstPoll(sender: UIButton) {
        fn_tabBarController.selectedIndex = 1
    }

    @IBAction func gearButtonPressed(sender: UIBarButtonItem) {
        let currentUser = ParseUser.current()

        // Buttons
        let defaultHandler: ((UIAlertAction!) -> Void) = { (action) -> Void in
            self.actionSheetAction(action.title)
        }
        var actions = [[String:String]]()
        actions += [["title": asLogOut, "style": "destructive"], ["title": asEditAccount]]
        // TODO: Link/Unlink Facebook
//        actions.append(["title": currentUser.isLoggedFacebook ? unlinkFacebookButtonTitle : linkFacebookButtonTitle])
        if currentUser.isAdmin {
            actions.append(["title": asMap])
        }
        actions.append(["title": FNLocalizedCancelButtonTitle, "style": "cancel"])

        // Presentation
        if NSClassFromString("UIAlertController") != nil {

            // iOS 8 and above
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            for action in actions {
                var style = UIAlertActionStyle.Default
                if let styleStr = action["style"] {
                    if styleStr == "destructive" {
                        style = .Destructive
                    } else if styleStr == "cancel" {
                        style = .Cancel
                    }
                }
                actionSheet.addAction(UIAlertAction(title: action["title"]!, style: style, handler: defaultHandler))
            }
            actionSheet.popoverPresentationController?.barButtonItem = sender
            presentViewController(actionSheet, animated: true, completion: nil)

        } else {

            // iOS 7
            let actionSheet = UIActionSheet()
            for action in actions {
                let idx = actionSheet.addButtonWithTitle(action["title"]!)
                if let styleStr = action["style"] {
                    if styleStr == "destructive" {
                        actionSheet.destructiveButtonIndex = idx
                    } else if styleStr == "cancel" {
                        actionSheet.cancelButtonIndex = idx
                    }
                }
            }
            actionSheet.delegate = self
            actionSheet.showFromBarButtonItem(sender, animated: true)
        }
    }

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        actionSheetAction(actionSheet.buttonTitleAtIndex(buttonIndex))
    }

    private func actionSheetAction(buttonTitle: String) {
        switch buttonTitle {

        case asLogOut:
            let activityIndicator = fn_tabBarController.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))
            ParseUser.logOutInBackgroundWithBlock({ (error) -> Void in
                activityIndicator.removeFromSuperview()
                FNAnalytics.logError(error, location: "Me: Log Out")
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
                self.fn_tabBarController.selectedIndex = 0
            })

        case asLinkFB:
            let activityIndicator = fn_tabBarController.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))
            PFFacebookUtils.linkUserInBackground(ParseUser.current(), withReadPermissions: FNFacebookReadPermissions, block: { (succeeded, error) -> Void in
                activityIndicator.removeFromSuperview()
                self.updateUserInfo()
                FNAnalytics.logError(error, location: "Me: Link Facebook")
            })

        case asUnlinkFB:
            let activityIndicator = fn_tabBarController.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))
            PFFacebookUtils.unlinkUserInBackground(ParseUser.current(), block: { (succeeded, error) -> Void in
                activityIndicator.removeFromSuperview()
                self.updateUserInfo()
                FNAnalytics.logError(error, location: "Me: Unlink Facebook")
            })

        case asEditAccount:
            performSegueWithIdentifier("Edit Account", sender: nil)

        case asMap:
            performSegueWithIdentifier("Users Map", sender: nil)
            
        default:
            break
        }
    }

    override func needsLogin() -> Bool {
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let unwrappedId = segue.identifier {

            switch unwrappedId {
            case "Result Controller":
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Bordered, target: nil, action: nil)
                let idx = (collectionView!.indexPathsForSelectedItems().first as! NSIndexPath).item
                (segue.destinationViewController as! ResultPollController).poll = poll(idx)
            default:
                navigationItem.backBarButtonItem = nil
            }
        }
    }

    func loginChanged(notification: NSNotification) {

        // Clean caches. Also load polls if new user is not anonymous
        user = ParseUser.current()
        userPolls = ParsePollList(parameters: ParsePollList.Parameters(type: .User(user)))
        postedPolls.removeAll(keepCapacity: false)
        collectionView!.reloadData()
        if ParseUser.current().isLogged {
            footer?.activityIndicator?.startAnimating()
            loadPolls()
        }
    }

    func pollDeleted(notification: NSNotification) {
        if let removedPoll = notification.userInfo?["poll"] as? ParsePoll, let index = userPolls.removePoll(removedPoll) {
            removedPoll.unpinInBackgroundWithBlock(nil)
            collectionView!.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
            updateFooterButton()
        }
    }

    func pollPosted(notification: NSNotification) {
        if let postedPoll = notification.userInfo?["poll"] as? ParsePoll {
            postedPolls.insert(postedPoll, atIndex: 0)
            collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
            updateFooterButton()
        }
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postedPolls.count + userPolls.count
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        // Header
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath) as! ProfileHeader
            self.header = header
            updateUserInfo()
            return header
        }

        // Footer
        let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Footer", forIndexPath: indexPath) as! ProfileFooter
        self.footer = footer
        return footer
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        // Get cell
        let cell = (collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as! MePollCell)

        // Set urls to check later if it is still the same cell
        let poll = self.poll(indexPath.row)

        if let leftImageUrl = poll.photos?[0].image?.url, let rightImageUrl = poll.photos?[1].image?.url {

            // If both images are already cached, just set them and return the cell
            cell.leftImageView.image = scaledImages[leftImageUrl]
            cell.rightImageView.image = scaledImages[rightImageUrl]
            if cell.leftImageView.image != nil && cell.rightImageView.image != nil {
                // Adjust aspect ratio
                cell.leftImageView.fn_setAspectRatio(image: nil)
                cell.rightImageView.fn_setAspectRatio(image: nil)
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

                    var itemSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in

                        scaledImage = image.scaleByFactor(Float(itemSize.height / image.size.height * UIScreen.mainScreen().scale))

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.scaledImages[urlString] = scaledImage

                            var imageView: UIImageView!
                            if urlString == leftImageUrl {
                                imageView = cell.leftImageView
                            } else if urlString == rightImageUrl {
                                imageView = cell.rightImageView
                            } else {
                                // Too late. Cell is already being used by another item. Just do nothing.
                                return
                            }

                            imageView.image = scaledImage
                            imageView.fn_setAspectRatio(image: scaledImage)

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
            manager.downloadImageWithURL(NSURL(string: leftImageUrl), options: nil, progress: nil, completed: completion)
            manager.downloadImageWithURL(NSURL(string: rightImageUrl), options: nil, progress: nil, completed: completion)
        }
        else {
            // TODO: Better error handling
            NSLog("MePollCell image download error: not enough URLs")
        }

        return cell
    }

    // MARK: (De)Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        if user == ParseUser.current() {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            notificationCenter.addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
            notificationCenter.addObserver(self, selector: "pollDeleted:", name: FNPollDeletedNotificationName, object: nil)
            notificationCenter.addObserver(self, selector: "pollPosted:", name: FNPollPostedNotificationName, object: nil)
            notificationCenter.addObserver(self, selector: "friendsUpdated:", name: ParseFriendsList.FinishLoadingNotification, object: nil)
            countButtonsEnabled = true
        }

        // Configure refresh control for manual update
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.lightGrayColor()
        refreshControl.layer.zPosition = -9999
        refreshControl.addTarget(self, action: "refreshControlDidChangeValue:", forControlEvents: .ValueChanged)
        collectionView!.addSubview(refreshControl)
        self.refreshControl = refreshControl
        collectionView!.alwaysBounceVertical = true

        // Set collection view item size
        let itemWidth = Int(((collectionView?.bounds.width ?? 320) - 8) / 3)
        (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: itemWidth, height: Int(itemWidth * 3 / 2))

        // Load polls
        userPolls = ParsePollList(parameters: ParsePollList.Parameters(type: .User(user)))
        loadPolls(showError: false)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUserInfo()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
}

class ProfileHeader: UICollectionReusableView {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var addFriendButton: UIButton!
}

class ProfileFooter: UICollectionReusableView {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var createBtn: UIButton!
}