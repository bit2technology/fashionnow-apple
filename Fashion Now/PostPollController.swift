//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, PhotoComparisonControllerDelegate {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var loadingView: UIView!
    
    weak var photoComparisonController: PhotoComparisonController!
    
    @IBAction func sendButtonPressed(sender: UIButton) {
        
        sender.enabled = false
        loadingView.hidden = false
        textField.enabled = false
        
//        photoComparisonController.poll.saveInBackgroundWithBlock { (succeeded, error) -> Void in
//            
//            self.photoComparisonController.clean(animated: true)
//            self.loadingView.hidden = true
//        }
    }
    
    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "Photo Comparison Controller":
                photoComparisonController = segue.destinationViewController as PhotoComparisonController
                
            default:
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendButton.tintColor = UIColor.defaultTintColor().colorWithAlphaComponent(0.6)

        sendButton.hidden = true
        loadingView.hidden = true
        
        photoComparisonController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        rootController?.delegate = self

        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {

            rootController?.presentLoginController()
        }
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }

    // MARK: PhotoComparisonControllerDelegate
    
    func photoComparisonController(photoComparisonController: PhotoComparisonController, didEditPoll poll: Poll) {

        // If poll is valid, show send button
        sendButton.hidden = (poll.createdBy == nil || poll.photos?.count < 2)
    }
}
