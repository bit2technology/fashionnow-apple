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
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var testLabel: UILabel!
    
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
    
    // MARK: Rotation

    override func supportedInterfaceOrientations() -> Int {
        
        var supportedInterfaceOrientations = UIInterfaceOrientationMask.AllButUpsideDown
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            supportedInterfaceOrientations = UIInterfaceOrientationMask.All
        }
        return Int(supportedInterfaceOrientations.rawValue)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        navBarTopMargin.constant = (rootController!.cleanInterface ? -navBar.frame.height : 0)
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootController?.delegate = self
        
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true
        
        //        testLabel.text = "Cupcake ipsum dolor sit amet pie. Pudding chocolate fruitcake apple pie sweet roll I love jelly beans ice cream. Brownie tootsie roll carrot cake lollipop lemon drops apple pie sugar plum macaroon biscuit."
        //        testLabel.textColor = UIColor.whiteColor()
        testLabel.layer.shadowColor = UIColor.whiteColor().CGColor
        testLabel.layer.shadowOffset = CGSizeZero
        testLabel.layer.shadowOpacity = 1
        testLabel.layer.shadowRadius = 2
        
        photoComparisonController.mode = .Vote
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.rootController?.delegate = self
        
        var query: PFQuery = PFQuery(className: Poll.parseClassName())
        query.includeKey("photos")
        query.includeKey("createdBy")
        query.orderByDescending("createdAt")
        
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
            let poll = object as Poll
            self.photoComparisonController.poll = poll
            
            // Name
            self.nameLabel.text = poll.createdBy?.username
            // Date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.doesRelativeDateFormatting = true
            self.dateLabel.text = dateFormatter.stringFromDate(poll.createdAt)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.rootController?.delegate = nil
    }
}
