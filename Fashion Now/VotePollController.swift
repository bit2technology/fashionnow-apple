//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController, PollControllerDelegate {
    
    var pollController: PollController!

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!

    var voteButtons: [UIButton]!
    @IBOutlet weak var leftVoteButton: UIButton!
    @IBOutlet weak var rightVoteButton: UIButton!

    private var cleanInterface: Bool = false {
        didSet {
            for voteButton in voteButtons {
                voteButton.alpha = (cleanInterface ? 0.2 : 1)
            }
        }
    }
    private func setCleanInterfaceIfNeeded(cleanInterface: Bool, animationDuration duration: NSTimeInterval) {
        if cleanInterface != self.cleanInterface {
            UIView.animateWithDuration(duration) { () -> Void in
                self.cleanInterface = cleanInterface
            }
        }
    }

    @IBAction func voteButtonWillBePressed(sender: UIButton) {

        setCleanInterfaceIfNeeded(false, animationDuration: 0.2)
    }
    @IBAction func voteButtonPressed(sender: UIButton) {

        pollController.animateAndVote(index: find(voteButtons, sender)!, easeIn: true)
    }

    @IBAction func tagsLabelDidLongPress(sender: UIGestureRecognizer) {

        switch sender.state {
        case .Began, .Changed:
            tagsLabel.numberOfLines = 0
        default:
            tagsLabel.numberOfLines = 2
        }
    }

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
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pollController.delegate = self
        pollController.dragEnabled = true
        
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true

        voteButtons = [leftVoteButton, rightVoteButton]
        for voteButton in voteButtons {
            voteButton.tintColor = UIColor.defaultTintColor(alpha: 0.6)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var query: PFQuery = PFQuery(className: Poll.parseClassName())
        query.includeKey("photos")
        query.includeKey("createdBy")
        query.orderByDescending("createdAt")
        
        query.getObjectInBackgroundWithId("s98wUwk2f4") { (object, error) -> Void in
//        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
            if let poll = object as? Poll {
                
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

    // MARK: PollControllerDelegate

    func pollControllerDidInteractVote(pollController: PollController) {

        setCleanInterfaceIfNeeded(true, animationDuration: 0.5)
    }
}
