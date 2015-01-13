//
//  FriendsListTableController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2015-01-13.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class FriendsListTableController: UITableViewController {

    var friendsList: [ParseUser]?

    var checkedIndexPaths = [NSIndexPath]()

    override func viewDidLoad() {
        super.viewDidLoad()

        FBRequestConnection.startForMyFriendsWithCompletionHandler { (requestConnection, object, error) -> Void in

            var friendsFacebookIds = [String]()
            for friendsFacebook in (object["data"] as [[String:String]]) {
                friendsFacebookIds.append(friendsFacebook["id"]!)
            }

            let friendsQuery = PFQuery(className: ParseUser.parseClassName())
            friendsQuery.whereKey(ParseUserFacebookIdKey, containedIn: friendsFacebookIds)
            friendsQuery.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in

                self.friendsList = objects as? [ParseUser]
                self.tableView.reloadData()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return friendsList != nil ? 2 : 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return 1
        }

        return friendsList?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Friends List Table Cell", forIndexPath: indexPath) as UITableViewCell

        cell.accessoryType = find(checkedIndexPaths, indexPath) != nil ? .Checkmark : .None

        if indexPath.section == 0 {

            cell.textLabel?.text = "Public"

            return cell
        }

        cell.textLabel?.text = friendsList?[indexPath.row].name

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
