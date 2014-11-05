//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController {
    
    var photoComparisonController: PhotoComparisonController!

    @IBOutlet weak var navBarTopMargin: NSLayoutConstraint!
    @IBOutlet weak var navBar: UINavigationBar!

    private var navBarHidden = false
    
    override func viewDidLoad() {

//        testLabel.text = "Cupcake ipsum dolor sit amet pie. Pudding chocolate fruitcake apple pie sweet roll I love jelly beans ice cream. Brownie tootsie roll carrot cake lollipop lemon drops apple pie sugar plum macaroon biscuit."
//        testLabel.textColor = UIColor.whiteColor()
//        testLabel.layer.shadowColor = UIColor.blackColor().CGColor
//        testLabel.layer.shadowOffset = CGSizeZero
//        testLabel.layer.shadowOpacity = 1
//        testLabel.layer.shadowRadius = 2
        
        photoComparisonController.mode = .Vote
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
        
        self.rootController?.delegate = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.rootController?.delegate = self
        
        var query: PFQuery = PFQuery(className: Poll.parseClassName())
        query.orderByDescending("createdAt")
        
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
            self.photoComparisonController.poll = object as Poll
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if respondsToSelector("traitCollection") {
            navBarHidden = (traitCollection.verticalSizeClass == .Compact)
        } else {
            navBarHidden = (interfaceOrientation.isLandscape && UIDevice.currentDevice().userInterfaceIdiom == .Phone)
        }

        navBarTopMargin.constant = (navBarHidden ? -navBar.frame.height : 0)

    }

    @IBAction func test(sender: UIButton!) {

    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {

    }
    
    func tabBarControllerSupportedInterfaceOrientations(tabBarController: UITabBarController) -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }
}
