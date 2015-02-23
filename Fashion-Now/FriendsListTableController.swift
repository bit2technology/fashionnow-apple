//
//  FriendsListTableController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2015-01-13.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class FriendsListTableController: UITableViewController, PostPollControllerDelegate {

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

        let pollACL = PFACL(user: ParseUser.currentUser())
        pollACL.setPublicReadAccess(false)
        for indexPath in checkedIndexPaths {
            if indexPath.section == 0 {
                pollACL.setPublicReadAccess(true)
            } else {
                pollACL.setReadAccess(true, forUser: friendsList![indexPath.row])
            }
        }
        poll.ACL = pollACL

        // Save locally, send poll to server and notify app

        poll.pin()
        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in

            if !succeeded {
                self.poll.saveEventually(nil)
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(NewPollSavedNotificationName, object: self, userInfo: ["poll": poll])

        // Return to previous controller to send a new poll

        showSentPollScreenAndReturn()
    }

    private func showSentPollScreenAndReturn() {

        // TODO: Sent Poll screen

        self.postPollController.clean()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return friendsList != nil ? 2 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return 1
        }

        return friendsList!.count > 0 ? friendsList!.count : 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: localize
        return ["General access", "Friends"][section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // Verify if it is a message cell
        if indexPath.section == 1 && friendsList!.count < 1 {

            let cell = tableView.dequeueReusableCellWithIdentifier("Message Cell", forIndexPath: indexPath) as UITableViewCell

            cell.textLabel?.text = error?.localizedDescription ?? "Unknown error"

            return cell
        }

        // Normal cells

        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as FriendListTableCell

        cell.accessoryType = find(checkedIndexPaths, indexPath) != nil ? .Checkmark : .None

        if indexPath.section == 0 {

            cell.avatarView.contentMode = .Center
            cell.avatarView.image = UIImage(named: "ButtonPublic")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("PUBLIC_SELECTION", value: "Public", comment: "String shown when user is setting the visibility of the poll")

            return cell
        }

        cell.avatarView.contentMode = .ScaleToFill
        let user = friendsList?[indexPath.row]
        if let unwrappedAuthorFacebookId = user?.facebookId {
            cell.avatarView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedAuthorFacebookId, size: 40), usingActivityIndicatorStyle: .White)
        } else {
            cell.avatarView.image = nil
        }
        cell.nameLabel.text = user?.name

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let cell = tableView.cellForRowAtIndexPath(indexPath)!

        let foundIndex = find(checkedIndexPaths, indexPath)
        if let unwrappedFoundIndex = foundIndex {
            checkedIndexPaths.removeAtIndex(unwrappedFoundIndex)
            cell.accessoryType = .None
        } else {
            checkedIndexPaths.append(indexPath)
            cell.accessoryType = .Checkmark
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        postPollController.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Post: Friends Selection", block: nil)
    }

    @IBAction func refreshControlDidChangeValue(sender: UIRefreshControl) {
        error = nil
        postPollController.cacheFriendsList()
    }

    func postPollControllerDidFinishDownloadFriendsList(friendsList: [ParseUser]) {

        refreshControl?.endRefreshing()

        if self.friendsList == nil || self.friendsList! != friendsList {
            self.friendsList = friendsList
            tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }
    }

    func postPollControllerDidFailDownloadFriendsList(error: NSError!) {
        self.error = error
        postPollControllerDidFinishDownloadFriendsList([])
    }
}

class FriendListTableCell: UITableViewCell {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true
    }
}
