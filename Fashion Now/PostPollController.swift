//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, PollControllerDelegate {

    private weak var pollController: PollController!

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var loadingView: UIView!

    @IBAction func sendButtonPressed(sender: UIButton) {
        
        sender.enabled = false
        loadingView.hidden = false
        textField.enabled = false

        let poll = pollController.poll
        poll.tags = textField.text?.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            
            sender.enabled = false
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
        
        sendButton.tintColor = UIColor.defaultTintColor(alpha: 0.6)

        sendButton.hidden = true
        loadingView.hidden = true

        pollController.delegate = self
        
//        pollController.leftPhotoController.delegate = self
//        pollController.rightPhotoController.delegate = self
    }

    // MARK: PollControllerDelegate
    
    func pollController(pollController: PollController, didEditPoll poll: ParsePoll) {
        sendButton.hidden = !poll.isValid
    }
}
