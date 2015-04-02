//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

private let transitionDuration: NSTimeInterval = 0.25

class VotePollController: UIViewController, PollInteractionDelegate, PollLoadDelegate, UIActionSheetDelegate, UIAlertViewDelegate {

    private var polls = ParsePollList(type: .VotePublic)

    private var currentPoll: ParsePoll?

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
                voteButton.alpha = (cleanInterface ? 0.2 : 1)
            }
        }
    }
    private func setCleanInterface(newValue: Bool, animated: Bool) {
        if newValue != cleanInterface {
            UIView.animateWithDuration(animated ? transitionDuration : 0) { () -> Void in
                self.cleanInterface = newValue
            }
        }
    }

    // Empty polls interface
    @IBOutlet weak var emptyInterface: UIView!

    // Loading interface
    private weak var loadingInterface: UIActivityIndicatorView!

    private let reportButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.reportButtonTitle", value: "Report Poll", comment: "Shown when user taps the gear button")
    private let skipButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.skipButtonTitle", value: "Skip Poll", comment: "Shown when user taps the gear button")
    private let filtersButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.filtersButtonTitle", value: "Apply Filters", comment: "Shown when user taps the gear button")
    private let refreshButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.refreshButtonTitle", value: "Refresh", comment: "Shown when user taps the gear button")
    private let loginButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.loginButtonTitle", value: "Log In", comment: "Shown when user taps the gear button")

    @IBAction func gearButtonPressed(sender: UIBarButtonItem) {

        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        // Buttons
        var otherButtonTitles = [String]()
        if currentPoll != nil {
            otherButtonTitles += [/*reportButtonTitle,*/ skipButtonTitle] // TODO: Add report
        }
        otherButtonTitles += [/*filtersButtonTitle,*/ refreshButtonTitle] // TODO: Add filters
        if PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) {
            otherButtonTitles.append(loginButtonTitle)
        }
        for buttonTitle in otherButtonTitles {
            actionSheet.addButtonWithTitle(buttonTitle)
        }
        actionSheet.cancelButtonIndex = actionSheet.addButtonWithTitle(FNLocalizedCancelButtonTitle)
        // Present
        actionSheet.showFromBarButtonItem(sender, animated: true)
    }

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        switch actionSheet.buttonTitleAtIndex(buttonIndex) {

        case skipButtonTitle:
            pollController.animateHighlight(index: 0, source: .Extern)

        case refreshButtonTitle:
            UIView.transitionWithView(self.navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
                self.loadPollList(nil)
            }, completion: nil)

        case loginButtonTitle:
            (tabBarController! as TabBarController).presentLoginController()

        default:
            break
        }
    }

    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        switch actionSheet.buttonTitleAtIndex(buttonIndex) {
        case reportButtonTitle:
            let alertView = UIAlertView(title: NSLocalizedString("VotePollController.gearButton.reportAlert.title", value: "Report Poll", comment: "Shown when user reports a poll"), message: NSLocalizedString("VotePollController.gearButton.reportAlert.message", value: "Tell us why you want to report this poll", comment: "Shown when user reports a poll"), delegate: self, cancelButtonTitle: FNLocalizedCancelButtonTitle, otherButtonTitles: NSLocalizedString("VotePollController.gearButton.reportAlert.reportButtonTitle", value: "Report", comment: "Shown when user reports a poll"))
            alertView.alertViewStyle = .PlainTextInput
            alertView.show()
        default:
            break
        }
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            // TODO: Report
            pollController.animateHighlight(index: 0, source: .Extern)
        }
    }

    private func showNextPoll() -> Bool {

        currentPoll = polls.nextPoll(remove: true)

        if let pollToShow = currentPoll {
            pollController.poll = pollToShow

            // Avatar
            if let avatarUrl = pollToShow.createdBy?.avatarURL(size: 33) {
                avatarView.setImageWithURL(avatarUrl, placeholderImage: UIColor.fn_placeholder().fn_image(), usingActivityIndicatorStyle: .White)
            } else {
                avatarView.image = nil
            }
            // Name
            nameLabel.text = pollToShow.createdBy?.name ?? pollToShow.createdBy?.email ?? NSLocalizedString("VotePollController.titleView.nameLabel.unknown", value: "Unknown", comment: "Shown when user has no name or email")
            // Date
            dateLabel.text = pollToShow.createdAt.timeAgoSinceNow()

            return true
        }
        else {
            avatarView.image = nil
            nameLabel.text = nil
            dateLabel.text = nil
            emptyInterface.hidden = false
            loadingInterface.stopAnimating()
            return false
        }
    }

    func loadPollList(notification: NSNotification?) {

        // Reset interface
        emptyInterface.hidden = true
        loadingInterface.startAnimating()
        avatarView.image = nil
        nameLabel.text = nil
        dateLabel.text = nil

        // Reload polls
        polls = ParsePollList(type: .VotePublic)
        polls.update(completionHandler: { (success, error) -> Void in

            UIView.transitionWithView(self.navigationController!.view, duration: notification == nil ? transitionDuration : 0, options: .TransitionCrossDissolve, animations: { () -> Void in
                self.showNextPoll()
                self.handle(error: error, location: .VoteControllerLoadList)
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

    private func handle(#error: NSError?, location: ErrorLocation?) {
        // TODO: Error handler
        if let errorToHandle = error {
            PFAnalytics.fn_trackErrorInBackground(errorToHandle, location: location ?? .VoteControllerHandle)
            loadingInterface.stopAnimating()
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.tabBarItem.selectedImage = UIImage(named: "TabBarIconVoteSelected")

        navigationItem.titleView!.frame.size.width = 9999

        loadingInterface = view.fn_setLoading(background: UIColor.groupTableViewBackgroundColor())

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
        PFAnalytics.fn_trackScreenInBackground("Vote: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate

    func pollLoaded(pollController: PollController) {
        UIView.transitionWithView(navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.loadingInterface.stopAnimating()
        }, completion: nil)
    }

    func pollLoadFailed(pollController: PollController, error: NSError) {
        UIView.transitionWithView(navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.handle(error: error, location: .VoteControllerPollLoadFail)
        }, completion: nil)
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
        PFAnalytics.fn_trackVote(index, method: voteMethod)

        let vote = ParseVote(user: ParseUser.currentUser())
        vote.pollId = pollController.poll.objectId
        vote.vote = index
        vote.saveEventually { (succeeded, error) -> Void in
            if error != nil {
                PFAnalytics.fn_trackErrorInBackground(error, location: .VoteControllerVoteSave)
            }
        }
    }

    func pollDidHighlight(pollController: PollController) {
        UIView.transitionWithView(navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.loadingInterface.startAnimating()
            self.showNextPoll()
        }, completion: nil)
    }
}
