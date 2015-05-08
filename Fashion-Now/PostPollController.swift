//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: FNViewController, PollEditionDelegate, UITextFieldDelegate {

    // Interface elements (strong ones are for remove/insert)
    private var textField: UITextField!
    private var sendButtonItem: UIBarButtonItem!
    private weak var pollController: PollController!

    // Interface for when user is not verified
    @IBOutlet var refreshInterface: UIView!
    @IBAction func resendVerification(sender: UIButton) {
    }
    @IBAction func alreadyVerified(sender: UIButton) {
    }

    @IBAction func pollControllerTapped(sender: UITapGestureRecognizer) {
        textField.resignFirstResponder()
    }

    func clean() {
        sendButtonItem.enabled = false
        textField.text = nil
        pollController.poll = ParsePoll(user: ParseUser.current())
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

            default:
                return
            }
        }
    }

    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPostSelected")

        // Interface adjustments
        textField = navigationItem.titleView as! UITextField
        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width
        sendButtonItem = navigationItem.rightBarButtonItem
        pollController.editDelegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clean", name: LoginChangedNotificationName, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Show refresh interface if user cannot post
        if !ParseUser.current().canPostPoll && find(view.subviews as! [UIView], refreshInterface) == nil {
            view.addSubview(refreshInterface)
            navigationItem.titleView = nil
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.titleView = textField
            navigationItem.rightBarButtonItem = sendButtonItem
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate
    
    func pollEdited(pollController: PollController) {
        sendButtonItem.enabled = pollController.poll.isValid
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}