//
//  FriendsListTableController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2015-01-13.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class FriendsListTableController: UITableViewController, PostPollControllerDelegate {

    private var checkedIndexPaths = [NSIndexPath]()

    weak var postPollController: PostPollController!

    @IBAction func backButtonPressed(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func sendButtonPressed(sender: UIBarButtonItem) {

        view.endEditing(true)

        // Adjust interface

        let sendButtonItem = navigationItem.rightBarButtonItem
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        navigationItem.setRightBarButtonItem(UIBarButtonItem(customView: activityIndicator), animated: true)
        navigationItem.leftBarButtonItem?.enabled = false

        // Send poll to server

        let poll = postPollController.poll?

        let pollACL = PFACL(user: ParseUser.currentUser())
        pollACL.setPublicReadAccess(false)
        for indexPath in checkedIndexPaths {
            if indexPath.section == 0 {
                pollACL.setPublicReadAccess(true)
            } else {
                pollACL.setReadAccess(true, forUser: postPollController.friendsList![indexPath.row])
            }
        }
        poll?.ACL = pollACL

        poll?.saveInBackgroundWithBlock { (succeeded, error) -> Void in

            if succeeded {
                self.postPollController.clean()
                self.navigationController?.popToRootViewControllerAnimated(true)
            } else {
                // FIXME: alert view
                UIAlertView(title: "error", message: "error", delegate: nil, cancelButtonTitle: "OK").show()
                self.navigationItem.setRightBarButtonItem(sendButtonItem, animated: true)
                self.navigationItem.leftBarButtonItem?.enabled = true
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return postPollController.friendsList != nil ? 2 : 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return 1
        }

        return postPollController.friendsList?.count ?? 0
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["General access", "Friends"][section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as FriendListTableCell

        cell.accessoryType = find(checkedIndexPaths, indexPath) != nil ? .Checkmark : .None

        if indexPath.section == 0 {

            cell.avatarView.contentMode = .Center
            cell.avatarView.image = UIImage(named: "ButtonPublic")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("PUBLIC_SELECTION", value: "Public", comment: "String shown when user is setting the visibility of the poll")

            return cell
        }

        cell.avatarView.contentMode = .ScaleToFill
        let user = postPollController.friendsList?[indexPath.row]
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

    func postPollControllerDidFinishDownloadFriendsList(postPollController: PostPollController) {
        let sections = NSIndexSet(indexesInRange: NSRange(0...1))
        self.tableView.reloadSections(sections, withRowAnimation: .Automatic)
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
