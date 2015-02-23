//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController, PollControllerDelegate {

    private var polls: ParsePublicVotePollList!

    private weak var pollController: PollController!

    // Navigation bar items
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    // Tags and related actions
    @IBOutlet weak var tagsLabel: UILabel!
    @IBAction func tagsLabelDidLongPress(sender: UIGestureRecognizer) {

        switch sender.state {
        case .Began, .Changed: // When touching caption view, show entire text.
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
        setCleanInterface(false, animated: true)
    }
    @IBAction func voteButtonPressed(sender: UIButton) {
        pollController.animateHighlight(index: find(voteButtons, sender)! + 1)
    }

    // Clean interface
    private var cleanInterface: Bool = false {
        didSet {
            for voteButton in voteButtons {
                voteButton.alpha = (cleanInterface ? 0.25 : 1)
            }
        }
    }
    private func setCleanInterface(cleanInterface: Bool, animated: Bool) {
        if cleanInterface != self.cleanInterface {
            if animated {
                UIView.animateWithDuration(0.15) { () -> Void in
                    self.cleanInterface = cleanInterface
                }
            } else {
                self.cleanInterface = cleanInterface
            }
        }
    }

    // Empty polls interface
    @IBOutlet weak var emptyInterface: UIView!

    // Loading interface
    @IBOutlet weak var loadingInterface: UIView!
    private func setLoadingInterfaceHidden(hidden: Bool, animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        if hidden != loadingInterface.hidden && animated {
            loadingInterface.hidden = false
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                // animations
                self.loadingInterface.alpha = (hidden ? 0 : 1)
            }, completion: { (finished) -> Void in
                // completion
                self.loadingInterface.hidden = hidden
                completion?(finished: finished)
            })
        } else {
            loadingInterface.hidden = hidden
            loadingInterface.alpha = (hidden ? 0 : 1)
            completion?(finished: true)
        }
    }

    private func showNextPoll() {

        if let nextPoll = self.polls.nextPoll(remove: true) {

            pollController.poll = nextPoll
            // Name
            nameLabel.text = nextPoll.createdBy?.name ?? nextPoll.createdBy?.email ?? NSLocalizedString("UNKNOW_USER", value: "Unknown", comment: "Shown when user has no name or email")
            // Date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.doesRelativeDateFormatting = true
            dateLabel.text = dateFormatter.stringFromDate(nextPoll.createdAt)
            // Caption
            if let unwrappedCaption = nextPoll.caption {
                tagsLabel.text = unwrappedCaption
            } else if let unwrappedTags = nextPoll.tags {
                tagsLabel.text = ", ".join(unwrappedTags).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            } else {
                tagsLabel.text = ""
            }
            tagsLabel.superview?.hidden = countElements(tagsLabel.text!) <= 0

            // Avatar
            if let unwrappedAuthorFacebookId = nextPoll.createdBy?.facebookId {
                avatarView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedAuthorFacebookId, size: 40), usingActivityIndicatorStyle: .White)
            } else {
                avatarView.image = nil
            }

        } else {

            // Adjust interface for no more polls
            emptyInterface.hidden = false
            setLoadingInterfaceHidden(true, animated: true, completion: nil)
        }
    }

    func loadPollList(notification: NSNotification?) {
        emptyInterface.hidden = true
        setLoadingInterfaceHidden(false, animated: false)
        polls = ParsePublicVotePollList()
        polls.update { (error) -> Void in

            if error != nil {
                self.showErrorScreen()
                return
            }

            self.showNextPoll()
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

    private func showErrorScreen() {
        // TODO: Error Screen
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPublicPollsSelected")

        pollController.delegate = self
        pollController.imageButtonsHidden = true
        pollController.voteGesturesEnabled = true
        
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true

        voteButtons = [leftVoteButton, rightVoteButton]
        for voteButton in voteButtons {
            voteButton.tintColor = UIColor.defaultTintColor(alpha: 0.5)
        }

        // Initializes poll list and adjusts interface
        loadPollList(nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadPollList:", name: LoginChangedNotificationName, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Vote: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate

    func pollControllerDidDidFinishLoad(pollController: PollController) {
        setLoadingInterfaceHidden(true, animated: false)
    }

    func pollControllerDidInteractWithInterface(pollController: PollController) {
        setCleanInterface(true, animated: true)
    }

    func pollControllerWillHighlight(pollController: PollController, index: Int) {

        let vote = ParseVote(user: ParseUser.currentUser())
        vote.pollId = pollController.poll.objectId
        vote.vote = index
        vote.saveEventually(nil)
    }

    func pollControllerDidHighlight(pollController: PollController) {
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "showLoadingInterfaceAndNextPoll:", userInfo: nil, repeats: false).fire()
    }
    func showLoadingInterfaceAndNextPoll(sender: NSTimer?) {
        setLoadingInterfaceHidden(false, animated: true) { (finished) -> Void in
            self.showNextPoll()
        }
    }
}
