//
//  PostFriendsController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-05-11.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

private let headerTitles = [NSLocalizedString("FriendsListTableController.headers.general", value: "General", comment: "Table view section header"), NSLocalizedString("FriendsListTableController.headers.friends", value: "Friends", comment: "Table view section header")]
private let selectAllBtnTitle = NSLocalizedString("FriendsListTableController.headers.selectAllButtonTitle", value: "Select All", comment: "Table view section header button to select all rows in that section")
private let deselectAllBtnTitle = NSLocalizedString("FriendsListTableController.headers.deselectAllButtonTitle", value: "Deselect All", comment: "Table view section header button to select all rows in that section")

class PostFriendsController: FNTableController {

    var poll: ParsePoll!

    // Marked rows
    private var checkedIndexPaths = [NSIndexPath]()

    private let friendsList = ParseFriendsList.shared

    // MARK: UITableViewController

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return friendsList.count
        default:
            return 1
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 2 ? 0 : 32
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        if section == 2 {
            return nil
        }

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 32))
        containerView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        // Title
        let title = UILabel(frame: CGRect(x: 8, y: 0, width: 192, height: 32))
        title.autoresizingMask = .FlexibleWidth
        title.font = UIFont.boldSystemFontOfSize(16)
        title.text =  headerTitles[section]
        containerView.addSubview(title)
        // Button
        if section == 1 && friendsList.count > 0 {
            let button = UIButton.buttonWithType(.System) as! UIButton
            button.frame = CGRect(x: 212, y: 0, width: 100, height: 32)
            button.autoresizingMask = .FlexibleLeftMargin
            button.setTitle(checkedIndexPaths.count < friendsList.count ? selectAllBtnTitle : deselectAllBtnTitle, forState: .Normal)
            button.addTarget(self, action: "selectAllFriends:", forControlEvents: .TouchUpInside)
            button.contentHorizontalAlignment = .Right
            containerView.addSubview(button)
        }
        // Finish
        return containerView
    }

    func selectAllFriends(sender: UIButton) {
        if checkedIndexPaths.count < friendsList.count {
            var allFriends = [NSIndexPath]()
            for i in 0 ..< friendsList.count {
                allFriends.append(NSIndexPath(forRow: i, inSection: 1))
            }
            checkedIndexPaths = allFriends
            sender.setTitle(deselectAllBtnTitle, forState: .Normal)
        } else {
            checkedIndexPaths.removeAll(keepCapacity: true)
            sender.setTitle(selectAllBtnTitle, forState: .Normal)
        }
        tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .None)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as! PostFriendsCell

        cell.accessoryType = find(checkedIndexPaths, indexPath) != nil ? .Checkmark : .None

        switch indexPath.section {

        case 0:
            cell.avatarView.image = UIImage(named: "FriendsPublic")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("FriendsListTableController.rowTitle.publicPoll", value: "Public Poll", comment: "Table view row title for make the poll public for all users")

        case 1:
            cell.avatarView.contentMode = .ScaleToFill
            let user = friendsList[indexPath.row]!
            cell.avatarView.setImageWithURL(user.avatarURL(size: 40), usingActivityIndicatorStyle: .White)
            cell.nameLabel.text = user.displayName

        case 2:
            cell.avatarView.image = UIImage(named: "FriendsInvite")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.nameLabel.text = NSLocalizedString("FriendsListTableController.rowTitle.inviteFriens", value: "Invite Friends", comment: "Table view row title for invite friends to use the app")

        default:
            break
        }
        
        return cell
    }
}

class PostFriendsCell: UITableViewCell {
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
}
