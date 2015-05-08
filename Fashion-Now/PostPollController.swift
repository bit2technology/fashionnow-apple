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
    private var textField: UITextField {
        return navigationItem.titleView as! UITextField
    }
    private weak var pollController: PollController!

    // Interface for when user is not verified
    @IBOutlet var refreshInterface: UIView!
    @IBAction func resendVerification(sender: UIButton) {
    }
    @IBAction func alreadyVerified(sender: UIButton) {
        // TODO: Use universal transition duration
        UIView.transitionWithView(view, duration: 0.25, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.refreshInterface.removeFromSuperview()
            self.textField.enabled = true
            self.pollEdited(self.pollController) // To set rightBarButtonItem
        }, completion: nil)
    }

    @IBAction func pollControllerTapped(sender: UITapGestureRecognizer) {
        textField.resignFirstResponder()
    }

    func clean() {
        navigationItem.rightBarButtonItem!.enabled = false
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
        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width
        pollController.editDelegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clean", name: LoginChangedNotificationName, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Show refresh interface if user cannot post
        if !ParseUser.current().canPostPoll && find(view.subviews as! [UIView], refreshInterface) == nil {
            view.addSubview(refreshInterface)
            textField.enabled = false
            navigationItem.rightBarButtonItem!.enabled = false
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate
    
    func pollEdited(pollController: PollController) {
        navigationItem.rightBarButtonItem!.enabled = pollController.poll.isValid
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}