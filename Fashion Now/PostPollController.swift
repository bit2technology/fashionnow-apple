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

    @IBAction func sendButtonPressed(sender: UIButton) {
        
        sender.enabled = false
        loadingView.hidden = false
        textField.enabled = false

        let poll = pollController.poll
        poll.caption = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in

            if succeeded {
                UIView.transitionWithView(self.navigationController!.view, duration: 0.25, options: .TransitionFlipFromRight, animations: { () -> Void in
                    sender.hidden = true
                    self.textField.text = nil
                    self.pollController.poll = ParsePoll(user: ParseUser.currentUser())
                }, completion: nil)
            }
            
            sender.enabled = true
            self.loadingView.hidden = true
            self.textField.enabled = true
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

        sendButton.tintColor = UIColor.whiteColor()
        sendButton.setTitleColor(UIColor.defaultTintColor(), forState: .Normal)

        sendButton.hidden = true
        loadingView.hidden = true

        pollController.delegate = self

        textField.delegate = self
    }

    // MARK: PollControllerDelegate
    
    func pollController(pollController: PollController, didEditPoll poll: ParsePoll) {

        if poll.isValid {
            sendButton.alpha = 1
            sendButton.hidden = false
        } else {
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.sendButton.alpha = 0
            }, completion: { (completed) -> Void in
                self.sendButton.hidden = true
            })
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
