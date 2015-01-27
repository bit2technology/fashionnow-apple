//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, PollControllerDelegate, UITextFieldDelegate {

    weak var delegate: PostPollControllerDelegate?

    private(set) var friendsList: [ParseUser]?

    private weak var pollController: PollController!
    var poll: ParsePoll? {
        get {
            return pollController?.poll
        }
    }

    @IBOutlet weak var textField: UITextField!

    @IBAction func pollControllerTapped(sender: AnyObject) {
        textField.resignFirstResponder()
    }

    func clean() {
        textField.text = nil
        navigationItem.rightBarButtonItem?.enabled = false
        pollController.poll = ParsePoll(user: ParseUser.currentUser())
    }
    
    // MARK: UIViewController
    
    override func needsLogin() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "Poll Controller":
                pollController = segue.destinationViewController as PollController

            case "Friends List":
                textField.resignFirstResponder()
                pollController.poll.caption = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                (segue.destinationViewController as? FriendsListTableController)?.postPollController = self

            default:
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPostPollSelected")

        pollController.delegate = self
        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width

        // Friends list cache
        FBRequestConnection.startForMyFriendsWithCompletionHandler { (requestConnection, object, error) -> Void in

            if error != nil {
                return
            }

            var friendsFacebookIds = [String]()
            let friendsFacebook = object["data"] as? [[String:String]]

            if friendsFacebook == nil {
                return
            }

            for friendFacebook in friendsFacebook! {
                friendsFacebookIds.append(friendFacebook["id"]!)
            }

            let friendsQuery = PFQuery(className: ParseUser.parseClassName())
            friendsQuery.whereKey(ParseUserFacebookIdKey, containedIn: friendsFacebookIds)
            friendsQuery.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in

                self.friendsList = objects as? [ParseUser]
                self.friendsList?.sort({$0.name < $1.name})
                self.delegate?.postPollControllerDidFinishDownloadFriendsList?(self)
            })
        }
    }

    // MARK: PollControllerDelegate
    
    func pollController(pollController: PollController, didEditPoll poll: ParsePoll) {
        navigationItem.rightBarButtonItem?.enabled = poll.isValid
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

@objc protocol PostPollControllerDelegate {

    optional func postPollControllerDidFinishDownloadFriendsList(postPollController: PostPollController)
}