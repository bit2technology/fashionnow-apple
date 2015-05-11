////
////  FriendsListTableController.swift
////  Fashion Now
////
////  Created by Igor Camilo on 2015-01-13.
////  Copyright (c) 2015 Bit2 Software. All rights reserved.
////
//
//class FriendsListTableController: FNTableController {
//
//    // Model
//    private var error: NSError?
//    var friendsList: [ParseUser]?
//    
//
//    // Access to previous controller
//    weak var postPollController: PostPollController!
//
//    @IBAction func sendButtonPressed(sender: UIBarButtonItem) {
//
//        // Choose poll visibility
//
//        let pollACL = PFACL(user: ParseUser.current())
//        pollACL.setPublicReadAccess(false)
//        var userIds = [String]()
//        for indexPath in checkedIndexPaths {
//            switch indexPath.section {
//            case 1:
//                pollACL.setPublicReadAccess(true)
//                pollACL.setPublicWriteAccess(true)
//            case 2:
//                let user = friendsList![indexPath.row]
//                pollACL.setReadAccess(true, forUser: user)
//                pollACL.setWriteAccess(true, forUser: user)
//                userIds.append(user.objectId!)
//            default:
//                break
//            }
//        }
//        poll.ACL = pollACL
//
//        // Save locally, send poll to server and notify app
//
//        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
//        activityIndicator.color = UIColor.grayColor()
//        activityIndicator.backgroundColor = UIColor.fn_white(alpha: 0.5)
//        activityIndicator.startAnimating()
//        activityIndicator.frame = navigationController!.view.bounds
//        activityIndicator.autoresizingMask = .FlexibleWidth | .FlexibleHeight
//        navigationController!.view.addSubview(activityIndicator)
//
//        poll.pin()
//        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in
//            activityIndicator.removeFromSuperview()
//
//            FNAnalytics.logError(error, location: "Friends List: Save Poll")
//
//            if succeeded {
//
//                var params = ["from": ParseUser.current().displayName, "to": userIds, "poll": self.poll.objectId!] as [NSObject:AnyObject]
//                if let caption = self.poll.caption?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) where caption.fn_count > 0 {
//                    params["caption"] = caption
//                }
//                PFCloud.callFunctionInBackground("sendPush", withParameters: params) { (result, error) -> Void in
//                    FNAnalytics.logError(error, location: "Friends List: Send Push")
//                }
//
//
//                FNToast.show(title: NSLocalizedString("FriendsListTableController.send.succeeded", value: "Poll sent", comment: "Shown when user sends the poll"), type: .Success)
//                NSNotificationCenter.defaultCenter().postNotificationName(FNPollPostedNotificationName, object: self, userInfo: ["poll": self.poll])
//                self.postPollController.clean()
//                self.navigationController!.popToRootViewControllerAnimated(true)
//            } else {
//                FNToast.show(title: NSLocalizedString("FriendsListTableController.send.fail", value: "Impossible to send", comment: "Shown when user sends the poll"), type: .Error)
//            }
//        }
//    }
//
//
//
//
//    
//
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//
//        if indexPath.section == 0 {
//            let activityController = UIActivityViewController(activityItems: [NSLocalizedString("FriendsListTableController.invite.caption", value: "Help me to choose my outfit with this app!", comment: "Default caption for when users are inviting friends"), NSURL(string: "http://www.fashionnowapp.com")!], applicationActivities: nil)
//            presentViewController(activityController, animated: true, completion: nil)
//            return
//        }
//
//        let cell = tableView.cellForRowAtIndexPath(indexPath)!
//
//        if let loadingCell = cell as? FriendsLoadingCell {
//            return
//        }
//
//        let foundIndex = find(checkedIndexPaths, indexPath)
//        if let unwrappedFoundIndex = foundIndex {
//            checkedIndexPaths.removeAtIndex(unwrappedFoundIndex)
//            cell.accessoryType = .None
//        } else {
//            checkedIndexPaths.append(indexPath)
//            cell.accessoryType = .Checkmark
//        }
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
//
////        postPollController.delegate = self
//    }
//
//    func loginChanged(sender: NSNotification) {
//        navigationController!.popToRootViewControllerAnimated(false)
//    }
//
//    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
//
//    @IBAction func refreshControlDidChangeValue(sender: UIRefreshControl) {
//        error = nil
////        postPollController.cacheFriendsList()
//    }
//
//    func postPollControllerDidFinishDownloadFriendsList(friendsList: [ParseUser]) {
//
//        refreshControl?.endRefreshing()
//
//        if self.friendsList == nil || self.friendsList! != friendsList {
//            self.friendsList = friendsList
//        }
//        tableView.reloadSections(NSIndexSet(index: 2), withRowAnimation: .Automatic)
//    }
//
//    func postPollControllerDidFailDownloadFriendsList(error: NSError!) {
//        self.error = error
//        postPollControllerDidFinishDownloadFriendsList([])
//    }
//}
//
//class FriendsLoadingCell: UITableViewCell {
//    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
//    @IBOutlet weak var messageLabel: UILabel!
//}
//
//class FriendListTableCell: UITableViewCell {
//    @IBOutlet weak var avatarView: UIImageView!
//    @IBOutlet weak var nameLabel: UILabel!
//}
