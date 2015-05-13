//
//  PostFriendsController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-05-11.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

private let headerTitles = [NSLocalizedString("PostFriendsController.headers.general", value: "General", comment: "Table view section header"), NSLocalizedString("PostFriendsController.headers.friends", value: "Friends", comment: "Table view section header")]
private let selectAllBtnTitle = NSLocalizedString("PostFriendsController.headers.selectAllButtonTitle", value: "Select All", comment: "Table view section header button to select all rows in that section")
private let deselectAllBtnTitle = NSLocalizedString("PostFriendsController.headers.deselectAllButtonTitle", value: "Deselect All", comment: "Table view section header button to select all rows in that section")

class PostFriendsController: FNTableController, UIAlertViewDelegate {

    // Sections
    var sectionPublicPoll: Int {
        return 0
    }
    var sectionFriends: Int {
        return 1
    }
    var sectionInvite: Int {
        return 2
    }

    var poll: ParsePoll!

    private var publicPoll = false

    /// Marked friends rows
    private var checkedFriendsRow = [Int]()

    private var allFriends: [Int] {
        var allFriends = [Int]()
        for i in 0 ..< friendsList.count {
            allFriends.append(i)
        }
        return allFriends
    }

    private let friendsList = ParseFriendsList.shared

    /// Reference to the (De)Select All button, so we can update its title
    private weak var selectAllBtn: UIButton?

    @IBAction func refreshControlDidChangeValue(sender: UIRefreshControl) {

        if fn_isOffline() {
            return
        }
        
        friendsList.update(true)
    }

    func friendsListFinishLoad(sender: NSNotification) {
        refreshControl!.endRefreshing()
        if !publicPoll {
            tableView.reloadSections(NSIndexSet(index: sectionFriends), withRowAnimation: .Automatic)
        }
    }

    @IBAction func sendButtonPressed(sender: UIBarButtonItem) {

        if !(publicPoll || checkedFriendsRow.count > 0) {
            let title = NSLocalizedString("PostFriendsController.send.invalidPollAlert.title", value: "Who Can See It?", comment: "Shown when user tries to send a poll to no one")
            let message = NSLocalizedString("PostFriendsController.send.invalidPollAlert.message", value: "You haven’t selected any friends… Would you like that everyone in the world could help you choosing?", comment: "Shown when user tries to send a poll to no one")
            let cancel = NSLocalizedString("PostFriendsController.send.invalidPollAlert.cancel", value: "Choose Friends", comment: "Shown when user tries to send a poll to no one")
            let send = NSLocalizedString("PostFriendsController.send.invalidPollAlert.title", value: "Send Public Poll", comment: "Shown when user tries to send a poll to no one")

            if NSClassFromString("UIAlertController") != nil {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: cancel, style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: send, style: .Default, handler: { (action) -> Void in
                    self.savePoll(true)
                }))
                presentViewController(alert, animated: true, completion: nil)
            } else {
                UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: send).show()
            }

            return
        }

        savePoll(false)
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            savePoll(true)
        }
    }

    private func savePoll(forcePublic: Bool) {

        if fn_isOffline() {
            return
        }

        // Choose poll visibility

        let pollACL = PFACL(user: ParseUser.current())
        var userIds = [String]()

        if forcePublic || publicPoll {
            for row in allFriends {
                userIds.append(friendsList[row]!.objectId!)
            }
            pollACL.setPublicReadAccess(true)
            pollACL.setPublicWriteAccess(true)
        } else {
            for row in checkedFriendsRow {
                let user = friendsList[row]!
                pollACL.setReadAccess(true, forUser: user)
                pollACL.setWriteAccess(true, forUser: user)
                userIds.append(user.objectId!)
            }
        }

        poll.ACL = pollACL

        // Save locally, send poll to server and notify app

        let activityIndicator = navigationController?.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))
        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            activityIndicator?.removeFromSuperview()

            FNAnalytics.logError(error, location: "Friends List: Save Poll")

            if succeeded {
                self.poll.pinInBackground() // FIXME: Maybe give it a name?

                var params = ["from": ParseUser.current().displayName, "to": userIds, "poll": self.poll.objectId!] as [NSObject:AnyObject]
                if let caption = self.poll.caption?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) where caption.fn_count > 0 {
                    params["caption"] = caption
                }
                PFCloud.callFunctionInBackground("sendPush", withParameters: params) { (result, error) -> Void in
                    FNAnalytics.logError(error, location: "Friends List: Send Push")
                }

                FNToast.show(title: NSLocalizedString("PostFriendsController.send.succeeded", value: "Poll sent", comment: "Shown when user sends the poll"), type: .Success)
                NSNotificationCenter.defaultCenter().postNotificationName(FNPollPostedNotificationName, object: self, userInfo: ["poll": self.poll])
            } else {
                FNToast.show(title: NSLocalizedString("PostFriendsController.send.fail", value: "Impossible to send", comment: "Shown when user sends the poll"), type: .Error)
            }
        }
    }

    // MARK: UITableViewController

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return publicPoll ? 1 : 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case sectionFriends:
            return friendsList.count
        default:
            return 1
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == sectionInvite ? 0 : 32
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        if section == 2 {
            return nil
        }

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 32))
        containerView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        // Title
        let title = UILabel(frame: CGRect(x: 8, y: 0, width: 312, height: 32))
        title.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        title.font = UIFont.boldSystemFontOfSize(16)
        title.text =  headerTitles[section]
        containerView.addSubview(title)
        // Button
        if section == 1 && friendsList.count > 0 {
            let button = UIButton.buttonWithType(.System) as! UIButton
            button.frame = containerView.bounds
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
            button.autoresizingMask = .FlexibleHeight | .FlexibleWidth
            button.setTitle(checkedFriendsRow.count < friendsList.count ? selectAllBtnTitle : deselectAllBtnTitle, forState: .Normal)
            button.addTarget(self, action: "selectAllFriends:", forControlEvents: .TouchUpInside)
            button.contentHorizontalAlignment = .Right
            containerView.addSubview(button)
            selectAllBtn = button
        }
        // Finish
        return containerView
    }

    /// Select or deselect all friends
    func selectAllFriends(sender: UIButton) {
        if checkedFriendsRow.count < friendsList.count {
            checkedFriendsRow = allFriends
            sender.setTitle(deselectAllBtnTitle, forState: .Normal)
        } else {
            checkedFriendsRow.removeAll(keepCapacity: true)
            sender.setTitle(selectAllBtnTitle, forState: .Normal)
        }
        tableView.reloadRowsAtIndexPaths(tableView.indexPathsForVisibleRows()!, withRowAnimation: .None)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as! PostFriendsCell

        switch indexPath.section {

        case sectionPublicPoll:
            cell.accessoryType = publicPoll ? .Checkmark : .None
            cell.avatarView.image = UIImage(named: "FriendsPublic")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("PostFriendsController.rowTitle.publicPoll", value: "All users", comment: "Table view row title for make the poll public for all users")

        case sectionFriends:
            cell.accessoryType = find(checkedFriendsRow, indexPath.row) != nil ? .Checkmark : .None
            cell.avatarView.cornerRadius = 20
            cell.avatarView.contentMode = .ScaleToFill
            let user = friendsList[indexPath.row]!
            cell.avatarView.removeActivityIndicator()
            cell.avatarView.sd_cancelCurrentImageLoad()
            cell.avatarView.setImageWithURL(user.avatarURL(size: 40), usingActivityIndicatorStyle: .White)
            cell.nameLabel.text = user.displayName

        case sectionInvite:
            cell.avatarView.cornerRadius = 0
            cell.avatarView.image = UIImage(named: "FriendsInvite")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("PostFriendsController.rowTitle.inviteFriens", value: "Invite friends", comment: "Table view row title for invite friends to use the app")

        default:
            break
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath)!

        switch indexPath.section {

        case sectionPublicPoll:
            publicPoll = !publicPoll
            let sections = NSIndexSet(indexesInRange: NSMakeRange(sectionFriends, 2))
            if publicPoll {
                tableView.deleteSections(sections, withRowAnimation: .Bottom)
                cell.accessoryType = .Checkmark
            } else {
                tableView.insertSections(sections, withRowAnimation: .Bottom)
                cell.accessoryType = .None
            }

        case sectionFriends:
            if let foundIndex = find(checkedFriendsRow, indexPath.row) {
                checkedFriendsRow.removeAtIndex(foundIndex)
                cell.accessoryType = .None
            } else {
                checkedFriendsRow.append(indexPath.row)
                cell.accessoryType = .Checkmark
            }
            selectAllBtn?.setTitle(checkedFriendsRow.count < friendsList.count ? selectAllBtnTitle : deselectAllBtnTitle, forState: .Normal)

        case sectionInvite:
            // TODO: Choose invite method
            let activityController = UIActivityViewController(activityItems: [NSLocalizedString("PostFriendsController.invite.caption", value: "Help me to choose my outfit with this app!", comment: "Default caption for when users are inviting friends"), NSURL(string: "http://www.fashionnowapp.com")!], applicationActivities: nil)
            presentViewController(activityController, animated: true, completion: nil)

        default:
            break
        }
    }

    // UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "friendsListFinishLoad:", name: ParseFriendsList.FinishLoadingNotification, object: friendsList)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

class PostFriendsCell: UITableViewCell {
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
}
