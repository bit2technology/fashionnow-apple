//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController, PollInteractionDelegate, PollLoadDelegate, UIActionSheetDelegate {

    private var polls = ParsePollList(type: .VotePublic)

    private weak var pollController: PollController!

    // Navigation bar items
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel, dateLabel: UILabel!

    // Vote buttons
    @IBOutlet weak var leftVoteButton, rightVoteButton: UIButton!
    private var voteButtons: [UIButton] {
        return [leftVoteButton, rightVoteButton]
    }
    // Press actions
    @IBAction func voteButtonWillBePressed(sender: UIButton) {
        setCleanInterface(false, animated: true)
    }
    @IBAction func voteButtonPressed(sender: UIButton) {
        pollController.animateHighlight(index: find(voteButtons, sender)! + 1, source: .Extern)
    }

    // Clean interface
    private var cleanInterface: Bool = false {
        didSet {
            for voteButton in voteButtons {
                voteButton.alpha = (cleanInterface ? 0.25 : 1)
            }
        }
    }
    private func setCleanInterface(newValue: Bool, animated: Bool) {
        if newValue != cleanInterface {
            UIView.animateWithDuration(animated ? 0.15 : 0) { () -> Void in
                self.cleanInterface = newValue
            }
        }
    }

    // Empty polls interface
    @IBOutlet weak var emptyInterface: UIView!

    // Loading interface
    private weak var loadingInterface: UIActivityIndicatorView!

    @IBAction func gearButtonPressed(sender: UIBarButtonItem) {
        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        // Buttons
        var otherButtonTitles = [String]()
        if PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) {
            otherButtonTitles.append(NSLocalizedString("VotePollController.gearButton.actionSheet.loginButtonTitle", value: "Log In", comment: "Shown when user taps the gear button"))
        }
        otherButtonTitles += [NSLocalizedString("VotePollController.gearButton.actionSheet.skipButtonTitle", value: "Skip", comment: "Shown when user taps the gear button"),
                              NSLocalizedString("VotePollController.gearButton.actionSheet.reportButtonTitle", value: "Report", comment: "Shown when user taps the gear button")]
        for buttonTitle in otherButtonTitles {
            actionSheet.addButtonWithTitle(buttonTitle)
        }
        actionSheet.cancelButtonIndex = actionSheet.addButtonWithTitle(FNLocalizedCancelButtonTitle)
        // Present
        actionSheet.showFromBarButtonItem(sender, animated: true)
    }

    private func showNextPoll() -> Bool {

        if let nextPoll = polls.nextPoll(remove: true) {
            pollController.poll = nextPoll

            // Avatar
            if let avatarUrl = nextPoll.createdBy?.avatarURL(size: 40) {
                avatarView.setImageWithURL(avatarUrl, placeholderImage: UIColor.fn_placeholder().fn_image(), usingActivityIndicatorStyle: .White)
            } else {
                avatarView.image = nil
            }
            // Name
            nameLabel.text = nextPoll.createdBy?.name ?? nextPoll.createdBy?.email ?? NSLocalizedString("VotePollController.titleView.nameLabel.unknown", value: "Unknown", comment: "Shown when user has no name or email")
            // Date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.doesRelativeDateFormatting = true
            dateLabel.text = dateFormatter.stringFromDate(nextPoll.createdAt)

            return true
        }
        else {
            avatarView.image = nil
            nameLabel.text = nil
            dateLabel.text = nil
            emptyInterface.hidden = false
            return false
        }
    }

    func loadPollList(notification: NSNotification?) {

        // Reset interface
        emptyInterface.hidden = true
        loadingInterface.startAnimating()

        // Reload polls
        polls = ParsePollList(type: .VotePublic)
        polls.update(completionHandler: { (success, error) -> Void in

            if error != nil {
                self.showErrorScreen(error)
                return
            }

            UIView.transitionWithView(self.navigationController!.view, duration: notification == nil ? 0.15 : 0, options: .TransitionCrossDissolve, animations: { () -> Void in
                self.loadingInterface.startAnimating()
                self.showNextPoll()
            }, completion: nil)
        })
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

    private func showErrorScreen(error: NSError!) {
        // TODO: Error Screen
        FNToast.show(text: error.localizedDescription, type: .Error)
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.tabBarItem.selectedImage = UIImage(named: "TabBarIconVoteSelected")

        navigationItem.titleView!.frame.size.width = 9999

        loadingInterface = view.fn_setLoading(background: UIColor.groupTableViewBackgroundColor())

        nameLabel.text = nil
        dateLabel.text = nil

        pollController.interactDelegate = self
        pollController.loadDelegate = self

        for voteButton in voteButtons {
            voteButton.tintColor = UIColor.fn_tint(alpha: 0.5)
        }

        // Initializes poll list and adjusts interface
        loadPollList(nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadPollList:", name: LoginChangedNotificationName, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.fn_trackScreenShowInBackground("Vote: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate

    func pollLoaded(pollController: PollController) {
        UIView.transitionWithView(navigationController!.view, duration: 0.15, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.loadingInterface.stopAnimating()
        }, completion: nil)
    }

    func pollLoadFailed(pollController: PollController, error: NSError) {
        showErrorScreen(error)
    }

    func pollInteracted(pollController: PollController) {
        setCleanInterface(true, animated: true)
    }

    func pollWillHighlight(pollController: PollController, index: Int, source: PollController.HighlightSource) {

        var voteMethod = "Button"
        if source == .DoubleTap {
            voteMethod = "Double Tap"
        } else if source == .Drag {
            voteMethod = "Drag"
        }
        PFAnalytics.fn_trackVoteMethodInBackground(voteMethod)

        let vote = ParseVote(user: ParseUser.currentUser())
        vote.pollId = pollController.poll.objectId
        vote.vote = index
        vote.saveEventually(nil)
    }

    func pollDidHighlight(pollController: PollController) {
        UIView.transitionWithView(navigationController!.view, duration: 0.15, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.loadingInterface.startAnimating()
            self.showNextPoll()
        }, completion: nil)
    }
}
