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

    /// Track if it's the first time the view is shown on screen
    private var firstTimeShow = true

    weak var refreshControl: UIRefreshControl!

    weak var header: MePollHeader?
    weak var footer: MePollFooter?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Basic configuration
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Bordered, target: nil, action: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

        // Configure refresh control for manual update
        let refreshControl = UIRefreshControl()
        refreshControl.layer.zPosition = -9999
        refreshControl.addTarget(self, action: "refreshControlDidChangeValue:", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        self.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true

        loadPolls()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if firstTimeShow {
            // Collection view item size
            let itemWidth = floor(((collectionView?.bounds.width ?? 320) - 8) / 3)
            (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: itemWidth, height: floor(itemWidth * 3 / 2))
            firstTimeShow = false
        }

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

    private func loadPolls(type: ParsePollList.UpdateType = .Newer, completionHandler: PFBooleanResultBlock? = nil) {

        var handler = completionHandler
        if handler == nil {
            handler = { (succeeded, error) -> Void in

                if succeeded {
                    self.postedPolls = []
                    self.collectionView?.reloadData()
                }

                if error != nil {
                    NSLog("My polls list update error: \(error)")
                }

                self.refreshControl.endRefreshing()
                self.footer?.prepare(updating: false)
            }
        }

        myPolls.update(type: type, completionHandler: handler!)
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

    override func awakeFromNib() {

        let layer = leftImageView.superview!.superview!.layer
        layer.rasterizationScale = UIScreen.mainScreen().scale
        layer.shouldRasterize = true

        let containers = [leftImageView.superview!, rightImageView.superview!]
        applyPollMask(containers.first!, containers.last!)
        for container in containers {
            container.layer.mask.transform = CATransform3DMakeScale(container.bounds.width, container.bounds.height, 1)
        }
    }

    func withPoll(poll: ParsePoll?) -> Self {

        let container = pollContainer
        container.hidden = true

        activityIndicator.startAnimating()
        leftImageView.image = nil
        rightImageView.image = nil

        let leftImageUrl = poll?.photos?.first?.image?.url
        let rightImageUrl = poll?.photos?.last?.image?.url

        if leftImageUrl != nil && rightImageUrl != nil {

            let completion: SDWebImageCompletionBlock = { (image, error, cacheType, url) -> Void in

                let urlString = url.absoluteString
                if leftImageUrl != urlString && rightImageUrl != urlString {
                    // Too late. Cell is already being used by another item. Just do nothing.
                    return
                }

                if image == nil {
                    // TODO: Better error handling
                    NSLog("MePollCell image download error: \(error)")
                    return
                }

                if self.leftImageView.image != nil && self.rightImageView.image != nil {
                    container.hidden = false
                    self.activityIndicator.stopAnimating()
                }
            }

            leftImageView.sd_setImageWithURL(NSURL(string: leftImageUrl!), completed: completion)
            rightImageView.sd_setImageWithURL(NSURL(string: rightImageUrl!), completed: completion)
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
            avatarImageView.setImageWithURL(currentUserUrl, placeholderImage: UIColor.defaultPlaceholderColor().image(), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
        nameLabel.text = currentUser.name

        return self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.image = UIColor.defaultPlaceholderColor().image()
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

