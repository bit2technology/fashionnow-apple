//
//  FriendsListTableController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2015-01-13.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class FriendsListTableController: FNTableController, PostPollControllerDelegate {

    // Model
    private var error: NSError?
    var friendsList: [ParseUser]?
    var poll: ParsePoll!

    // Marked rows
    private var checkedIndexPaths = [NSIndexPath]()

    // Access to previous controller
    weak var postPollController: PostPollController!

    @IBAction func sendButtonPressed(sender: UIBarButtonItem) {

        // Choose poll visibility

        let pollACL = PFACL(user: ParseUser.current())
        pollACL.setPublicReadAccess(false)
        var userIds = [String]()
        for indexPath in checkedIndexPaths {
            switch indexPath.section {
            case 1:
                pollACL.setPublicReadAccess(true)
                pollACL.setPublicWriteAccess(true)
            case 2:
                let user = friendsList![indexPath.row]
                pollACL.setReadAccess(true, forUser: user)
                pollACL.setWriteAccess(true, forUser: user)
                userIds.append(user.objectId!)
            default:
                break
            }
        }
        poll.ACL = pollACL

        // Save locally, send poll to server and notify app

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor.grayColor()
        activityIndicator.backgroundColor = UIColor.fn_white(alpha: 0.5)
        activityIndicator.startAnimating()
        activityIndicator.frame = navigationController!.view.bounds
        activityIndicator.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        navigationController!.view.addSubview(activityIndicator)

        poll.pin()
        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            activityIndicator.removeFromSuperview()

            FNAnalytics.logError(error, location: "Friends List: Save Poll")

            if succeeded {

                var params = ["from": ParseUser.current().displayName, "to": userIds, "poll": self.poll.objectId!] as [NSObject:AnyObject]
                if let caption = self.poll.caption?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) where caption.fn_count > 0 {
                    params["caption"] = caption
                }
                PFCloud.callFunctionInBackground("sendPush", withParameters: params) { (result, error) -> Void in
                    FNAnalytics.logError(error, location: "Friends List: Send Push")
                }


                FNToast.show(title: NSLocalizedString("FriendsListTableController.send.succeeded", value: "Poll sent", comment: "Shown when user sends the poll"), type: .Success)
                NSNotificationCenter.defaultCenter().postNotificationName(FNPollPostedNotificationName, object: self, userInfo: ["poll": self.poll])
                self.postPollController.clean()
                self.navigationController!.popToRootViewControllerAnimated(true)
            } else {
                FNToast.show(title: NSLocalizedString("FriendsListTableController.send.fail", value: "Impossible to send", comment: "Shown when user sends the poll"), type: .Error)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2:
            return max((friendsList?.count ?? 0), 1)
        default:
            return 1
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 32
    }

    private let headerTitles = [NSLocalizedString("FriendsListTableController.headers.general", value: "General", comment: "Table view section header"), NSLocalizedString("FriendsListTableController.headers.friends", value: "Friends", comment: "Table view section header")]
    private let selectAllButtonTitle = NSLocalizedString("FriendsListTableController.headers.selectAllButtonTitle", value: "All", comment: "Table view section header button to select all rows in that section")
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 32))
        containerView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        // Title
        let title = UILabel(frame: CGRect(x: 8, y: 0, width: 192, height: 32))
        title.autoresizingMask = .FlexibleWidth
        title.font = UIFont.boldSystemFontOfSize(16)
        title.text =  headerTitles[section - 1]
        containerView.addSubview(title)
        // Button
        if section == 2 && friendsList?.count > 0 {
            let button = UIButton.buttonWithType(.System) as! UIButton
            button.frame = CGRect(x: 212, y: 0, width: 100, height: 32)
            button.autoresizingMask = .FlexibleLeftMargin
            button.setTitle(selectAllButtonTitle, forState: .Normal)
            button.addTarget(self, action: "selectAllFriends:", forControlEvents: .TouchUpInside)
            button.contentHorizontalAlignment = .Right
            containerView.addSubview(button)
        }
        // Finish
        return containerView
    }

    func selectAllFriends(sender: UIButton) {
        for i in 0 ..< (friendsList?.count ?? 0) {
            let indexPath = NSIndexPath(forRow: i, inSection: 2)
            if find(checkedIndexPaths, indexPath) == nil {
                checkedIndexPaths.append(indexPath)
            }
        }
        tableView.reloadSections(NSIndexSet(index: 2), withRowAnimation: .None)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // Verify if it is a message cell
        if indexPath.section == 2 && indexPath.row == (friendsList?.count ?? 0) {

            let cell = tableView.dequeueReusableCellWithIdentifier("Loading Cell", forIndexPath: indexPath) as! FriendsLoadingCell

            cell.activityIndicator.stopAnimating()

            if friendsList == nil && error != nil {
                cell.activityIndicator.startAnimating()
            } else {
                cell.messageLabel.text = NSLocalizedString("FriendsListTableController.rowTitle.noFriends", value: "No Friends", comment: "Table view row title for when user has no friends")
            }

            return cell
        }

        // Normal cells

        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as! FriendListTableCell

        cell.accessoryType = find(checkedIndexPaths, indexPath) != nil ? .Checkmark : .None

        switch indexPath.section {

        case 0:
            cell.avatarView.image = UIImage(named: "FriendsInvite")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("FriendsListTableController.rowTitle.inviteFriens", value: "Invite Friends", comment: "Table view row title for invite friends to use the app")

        case 1:
            cell.avatarView.image = UIImage(named: "FriendsPublic")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("FriendsListTableController.rowTitle.publicPoll", value: "Public Poll", comment: "Table view row title for make the poll public for all users")

        case 2:
            cell.avatarView.contentMode = .ScaleToFill
            let user = friendsList![indexPath.row]
            cell.avatarView.setImageWithURL(user.avatarURL(size: 40), usingActivityIndicatorStyle: .White)
            cell.nameLabel.text = user.name

        default:
            break
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if indexPath.section == 0 {
            let activityController = UIActivityViewController(activityItems: [NSLocalizedString("FriendsListTableController.invite.caption", value: "Help me to choose my outfit with this app!", comment: "Default caption for when users are inviting friends"), NSURL(string: "http://www.fashionnowapp.com")!], applicationActivities: nil)
            presentViewController(activityController, animated: true, completion: nil)
            return
        }

        let cell = tableView.cellForRowAtIndexPath(indexPath)!

        if let loadingCell = cell as? FriendsLoadingCell {
            return
        }

        let foundIndex = find(checkedIndexPaths, indexPath)
        if let unwrappedFoundIndex = foundIndex {
            checkedIndexPaths.removeAtIndex(unwrappedFoundIndex)
            cell.accessoryType = .None
        } else {
            checkedIndexPaths.append(indexPath)
            cell.accessoryType = .Checkmark
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

        postPollController.delegate = self
    }

    func loginChanged(sender: NSNotification) {
        navigationController!.popToRootViewControllerAnimated(false)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @IBAction func refreshControlDidChangeValue(sender: UIRefreshControl) {
        error = nil
        postPollController.cacheFriendsList()
    }

    func postPollControllerDidFinishDownloadFriendsList(friendsList: [ParseUser]) {

        refreshControl?.endRefreshing()

        if self.friendsList == nil || self.friendsList! != friendsList {
            self.friendsList = friendsList
        }
        tableView.reloadSections(NSIndexSet(index: 2), withRowAnimation: .Automatic)
    }

    func postPollControllerDidFailDownloadFriendsList(error: NSError!) {
        self.error = error
        postPollControllerDidFinishDownloadFriendsList([])
    }
}

class FriendsLoadingCell: UITableViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
}

class FriendListTableCell: UITableViewCell {
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
}
