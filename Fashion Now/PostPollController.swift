//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, PollControllerDelegate, UITextFieldDelegate {

    private weak var pollController: PollController!

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var loadingView: UIView!

    @IBAction func navigationBarTapped(sender: AnyObject) {
        textField.becomeFirstResponder()
    }

    @IBAction func pollControllerTapped(sender: AnyObject) {
        view.endEditing(true)
    }

    @IBAction func sendButtonPressed(sender: UIButton) {

        view.endEditing(true)

        // Adjust interface

        UIView.transitionWithView(textField.superview!, duration: 0.15, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.textField.enabled = false
        }, completion: nil)

        UIView.transitionWithView(sender.superview!, duration: 0.15, options: .TransitionFlipFromRight, animations: { () -> Void in
            sender.hidden = true
            self.loadingView.hidden = false
        }, completion: nil)

        // Send poll to server

        let poll = pollController.poll
        poll.caption = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in

            if succeeded {
                UIView.transitionWithView(self.navigationController!.view, duration: 0.25, options: .TransitionFlipFromRight, animations: { () -> Void in

                    // Clean interface to new poll

                    sender.hidden = false
                    self.loadingView.hidden = true
                    self.textField.enabled = true
                    self.textField.text = nil
                    self.pollController.poll = ParsePoll(user: ParseUser.currentUser())
                }, completion: nil)
            } else {

                // Revert interface adjustments

                UIView.transitionWithView(self.textField.superview!, duration: 0.15, options: .TransitionCrossDissolve, animations: { () -> Void in
                    self.textField.enabled = true
                }, completion: nil)

                UIView.transitionWithView(sender.superview!, duration: 0.15, options: .TransitionFlipFromRight, animations: { () -> Void in
                    sender.hidden = false
                    self.loadingView.hidden = true
                }, completion: nil)
            }
        }
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
                
            default:
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPostPollSelected")

        sendButton.enabled = false
        loadingView.hidden = true

        pollController.delegate = self

        textField.delegate = self
    }

    // MARK: PollControllerDelegate
    
    func pollController(pollController: PollController, didEditPoll poll: ParsePoll) {
        sendButton.enabled = poll.isValid
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
