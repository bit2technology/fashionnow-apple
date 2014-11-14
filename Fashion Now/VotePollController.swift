//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController {
    
    var pollController: PollController!

    @IBOutlet weak var navBarTopMargin: NSLayoutConstraint!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    weak var tagsGradientBackgroundLayer: CAGradientLayer!
    
    // MARK: UIViewController
    
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
    
    // MARK: Rotation

    override func supportedInterfaceOrientations() -> Int {
        
        var supportedInterfaceOrientations = UIInterfaceOrientationMask.AllButUpsideDown
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            supportedInterfaceOrientations = UIInterfaceOrientationMask.All
        }
        return Int(supportedInterfaceOrientations.rawValue)
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var query: PFQuery = PFQuery(className: Poll.parseClassName())
        query.includeKey("photos")
        query.includeKey("createdBy")
        query.orderByDescending("createdAt")
        
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
            let poll = object as Poll
            self.pollController.poll = poll
            
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
}
