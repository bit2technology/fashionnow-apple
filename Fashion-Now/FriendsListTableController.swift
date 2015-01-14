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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as FriendListTableCell

        cell.accessoryType = find(checkedIndexPaths, indexPath) != nil ? .Checkmark : .None

        if indexPath.section == 0 {

            cell.nameLabel.text = "Public"

            return cell
        }

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
        self.tableView.reloadData()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

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
