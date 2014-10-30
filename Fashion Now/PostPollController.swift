//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, PhotoComparisonControllerDelegate {
    
    private var poll: Poll?

    @IBOutlet var sendButton: UIButton!
    @IBOutlet var loadingView: UIView!
    
    var photoComparisonController: PhotoComparisonController!
    
    @IBAction func sendButtonPressed(sender: UIButton) {
        loadingView.hidden = false
        
        poll?.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            println("error:\(error)")
            self.loadingView.hidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendButton.hidden = true
        loadingView.hidden = true
        
        photoComparisonController.delegate = self
    }
    
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
    
    func photoComparisonController(photoComparisonController: PhotoComparisonController, didEditPoll poll: Poll) {
        
        if poll.isValid {
            self.poll = poll
            sendButton.hidden = false
        } else {
            self.poll = nil
            sendButton.hidden = true
        }
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
}
