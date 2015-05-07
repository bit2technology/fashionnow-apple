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
    @IBOutlet var textField: UITextField!
    private var sendButtonItem: UIBarButtonItem!
    private weak var pollController: PollController!

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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPostSelected")

        // Interface adjustments
        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width
        sendButtonItem = navigationItem.rightBarButtonItem
        pollController.editDelegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clean", name: LoginChangedNotificationName, object: nil)
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