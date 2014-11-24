//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController, PollControllerDelegate {
    
    private weak var pollController: PollController!
    private var polls: [ParsePoll]?

    // Navigation bar items
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    // Tags and actions
    @IBOutlet weak var tagsLabel: UILabel!
    @IBAction func tagsLabelDidLongPress(sender: UIGestureRecognizer) {

        switch sender.state {
        case .Began, .Changed:
            tagsLabel.numberOfLines = 0
        default:
            tagsLabel.numberOfLines = 2
        }
    }

    // Vote buttons
    private var voteButtons: [UIButton]!
    @IBOutlet weak var leftVoteButton: UIButton!
    @IBOutlet weak var rightVoteButton: UIButton!
    // Press actions
    @IBAction func voteButtonWillBePressed(sender: UIButton) {
        setCleanInterfaceIfNeeded(false, animationDuration: 0.2)
    }
    @IBAction func voteButtonPressed(sender: UIButton) {
        pollController.animateAndVote(index: find(voteButtons, sender)!, easeIn: true)
    }

    // Clean interface
    private var cleanInterface: Bool = false {
        didSet {
            for voteButton in voteButtons {
                voteButton.alpha = (cleanInterface ? 0.25 : 1)
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

    // Loading interface
    @IBOutlet weak var loadingInterface: UIView!
    private func setLoadingInterfaceHiddenIfNeededAnimated(hidden: Bool, delay: NSTimeInterval, showNextPollWhenDone showNextPoll: Bool) {
        if hidden != loadingInterface.hidden {
            loadingInterface.hidden = false
            UIView.animateWithDuration(0.5, delay: delay, options: nil, animations: { () -> Void in
                // animations
                self.loadingInterface.alpha = (hidden ? 0 : 1)
            }, completion: { (succeeded) -> Void in
                // completion
                self.loadingInterface.hidden = hidden
                if showNextPoll {
                    self.showNextPoll()
                }
            })
        }
    }

    private func showNextPoll() {

        if polls == nil || polls!.count < 1 {
            return
        }

        let newPoll = polls!.last!
        polls!.removeLast()

        pollController.poll = newPoll
        // Name
        nameLabel.text = newPoll.createdBy?.username
        // Date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        dateLabel.text = dateFormatter.stringFromDate(newPoll.createdAt)
        // Tags
        if let unwrappedTags = newPoll.tags {
            tagsLabel.text = ", ".join(unwrappedTags)
            tagsLabel.superview?.hidden = false
        } else {
            tagsLabel.superview?.hidden = true
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

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconFriendsPollsSelected")

        pollController.delegate = self
        pollController.dragEnabled = true
        
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true

        voteButtons = [leftVoteButton, rightVoteButton]
        for voteButton in voteButtons {
            voteButton.tintColor = UIColor.defaultTintColor(alpha: 0.6)
        }
        
        loadingInterface.hidden = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var publicPollsQuery: PFQuery = PFQuery(className: ParsePoll.parseClassName())
        publicPollsQuery.includeKey(ParsePollPhotosKey)
        publicPollsQuery.includeKey(ParsePollCreatedByKey)
        publicPollsQuery.orderByAscending(ParseObjectCreatedAtKey)
        publicPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            if let unwrappedObjects = objects as? [ParsePoll] {
                self.polls = unwrappedObjects
                self.showNextPoll()
            }
        }
    }

    // MARK: PollControllerDelegate

    func pollControllerDidInteractWithVoteInterface(pollController: PollController) {
        setCleanInterfaceIfNeeded(true, animationDuration: 0.5)
    }

    func pollControllerDidVote(pollController: PollController, animated: Bool) {
        setLoadingInterfaceHiddenIfNeededAnimated(false, delay: 1, showNextPollWhenDone: true)
    }

    func pollControllerDidDidFinishLoad(pollController: PollController) {
        setLoadingInterfaceHiddenIfNeededAnimated(true, delay: 0, showNextPollWhenDone: false)
    }
}
