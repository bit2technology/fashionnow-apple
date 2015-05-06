//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: FNViewController, PollEditionDelegate, UITextFieldDelegate {

    // Interface elements
    @IBOutlet weak var textField: UITextField!
    private weak var pollController: PollController!

    // Friends list
    weak var delegate: PostPollControllerDelegate?
    private var cachedFriendsList: [ParseUser]?

    @IBAction func pollControllerTapped(sender: AnyObject) {
        textField.resignFirstResponder()
    }

    func clean() {
        navigationItem.rightBarButtonItem?.enabled = false
        textField.text = nil
        pollController.poll = ParsePoll(user: ParseUser.current())
        cachedFriendsList = nil
    }

    private var downloadingFriendsList = false
    func cacheFriendsList() {

        if downloadingFriendsList {
            // Already downloading. Just do nothing.
            return
        }

        downloadingFriendsList = true
        FBSDKGraphRequest(graphPath: "me/friends?limit=1000", parameters: nil).startWithCompletionHandler({ (requestConnection, object, error) -> Void in
            self.downloadingFriendsList = false

            if error != nil {
                FNAnalytics.logError(error, location: "Post: Cache Friends Facebook Request")
                self.delegate?.postPollControllerDidFailDownloadFriendsList(error)
                return
            }

            // Get list of IDs from friends
            var friendsFacebookIds = [String]()
            if let friendsFacebook = object["data"] as? [[String:String]] {

                for friendFacebook in friendsFacebook {
                    friendsFacebookIds.append(friendFacebook["id"]!)
                }

                // Get parse users from Facebook friends
                let friendsQuery = PFQuery(className: ParseUser.parseClassName())
                friendsQuery.whereKey(ParseUserFacebookIdKey, containedIn: friendsFacebookIds)
                friendsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

                    if FNAnalytics.logError(error, location: "Post: Cache Friends Query") {
                        self.delegate?.postPollControllerDidFailDownloadFriendsList(error)
                        return
                    }

                    self.cachedFriendsList = (objects as? [ParseUser]) ?? []
                    self.cachedFriendsList!.sort({$0.name < $1.name})
                    self.delegate?.postPollControllerDidFinishDownloadFriendsList(self.cachedFriendsList!)
                }
            } else {
                let noDataError = NSError(fn_code: .NoData)
                FNAnalytics.logError(noDataError, location: "Post: Cache Friends Facebook Request")
                self.delegate?.postPollControllerDidFailDownloadFriendsList(noDataError)
            }
        })
    }
    
    // MARK: UIViewController
    
    override func needsLogin() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "Poll Controller":
                pollController = segue.destinationViewController as! PollController

            case "Friends List":
                textField.resignFirstResponder()
                pollController.poll.caption = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let friendsListController = segue.destinationViewController as! FriendsListTableController
                friendsListController.friendsList = cachedFriendsList
                friendsListController.poll = pollController.poll
                friendsListController.postPollController = self

            default:
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPostSelected")

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clean", name: LoginChangedNotificationName, object: nil)

        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width
        pollController.editDelegate = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !(cachedFriendsList?.count > 0) {
            cacheFriendsList()
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate
    
    func pollEdited(pollController: PollController) {
        navigationItem.rightBarButtonItem?.enabled = pollController.poll.isValid
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

protocol PostPollControllerDelegate: class {

    func postPollControllerDidFinishDownloadFriendsList(friendsList: [ParseUser])
    func postPollControllerDidFailDownloadFriendsList(error: NSError!)
}