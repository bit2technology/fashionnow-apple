//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController, UITabBarControllerDelegate {
    
    var photoComparisonController: PhotoComparisonController!
    
    override func viewDidLoad() {
        
//        photoComparisonController.mode = .Vote
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

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.delegate = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tabBarController?.delegate = self
        
        UIViewController.attemptRotationToDeviceOrientation()
        
        var query: PFQuery = PFQuery(className: Poll.parseClassName())
        query.orderByDescending("createdAt")
        
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
//            self.photoComparisonController.poll = object as Poll
        }
    }
    
    func tabBarControllerSupportedInterfaceOrientations(tabBarController: UITabBarController) -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }
}
