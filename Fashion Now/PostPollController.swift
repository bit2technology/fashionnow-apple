//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, UITabBarControllerDelegate, PhotoComparisonControllerDelegate {
    
    private var poll: Poll?

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    
    weak var photoComparisonController: PhotoComparisonController!
    
    @IBAction func sendButtonPressed(sender: UIButton) {
        
        loadingView.hidden = false
        
        poll?.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            
            self.photoComparisonController.clean(animated: true)
            self.loadingView.hidden = true
        }
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

//        sendButton.hidden = true
//        loadingView.hidden = true
//        
//        photoComparisonController.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tabBarController?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.delegate = nil
    }
    
    func tabBarControllerSupportedInterfaceOrientations(tabBarController: UITabBarController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: PhotoComparisonControllerDelegate
    
    func photoComparisonController(photoComparisonController: PhotoComparisonController, didEditPoll poll: Poll) {
        
        if poll.createdBy != nil && poll.photos?.count >= 2 {
            self.poll = poll
            sendButton.hidden = false
        } else {
            self.poll = nil
            sendButton.hidden = true
        }
    }
}
