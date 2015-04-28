//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

private let transitionDuration: NSTimeInterval = 0.25

private let reportButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.reportButtonTitle", value: "Report Poll", comment: "Shown when user taps the gear button")
private let skipButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.skipButtonTitle", value: "Skip Poll", comment: "Shown when user taps the gear button")
private let filtersButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.filtersButtonTitle", value: "Apply Filters", comment: "Shown when user taps the gear button")
private let refreshButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.refreshButtonTitle", value: "Refresh", comment: "Shown when user taps the gear button")
private let loginButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.loginButtonTitle", value: "Log In", comment: "Shown when user taps the gear button")

class VotePollController: FNViewController, PollInteractionDelegate, PollLoadDelegate, UIActionSheetDelegate, UIAlertViewDelegate, EAIntroDelegate {

    private var polls = ParsePollList(type: .VotePublic)

    private var currentPoll: ParsePoll?

    private weak var pollController: PollController!

    private var statusBarStyle = UIStatusBarStyle.Default

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

    // Message interface with a button to refresh
    @IBOutlet weak var refreshMessage: UILabel!
    private func setRefreshMessage(text: String? = nil, hidden: Bool = false) {
        refreshMessage.text = text
        refreshMessage.superview!.superview!.hidden = hidden
    }

    // Loading interface
    private weak var loadingInterface: UIActivityIndicatorView!

    @IBAction func gearButtonPressed(sender: UIBarButtonItem) {

        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        // Buttons
        var otherButtonTitles = [String]()
        if currentPoll != nil {
            otherButtonTitles += [reportButtonTitle, skipButtonTitle]
        }
        otherButtonTitles += [/*filtersButtonTitle,*/ refreshButtonTitle] // TODO: Add filters
        if PFAnonymousUtils.isLinkedWithUser(ParseUser.current()) {
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
            (tabBarController as! TabBarController).presentLoginController()

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
            let createdBy = pollToShow.createdBy
            nameLabel.text = createdBy?.displayName
            // Date
            dateLabel.text = pollToShow.createdAt!.timeAgoSinceNow()

            return true
        }
        else {
            avatarView.image = nil
            nameLabel.text = nil
            dateLabel.text = nil
            setRefreshMessage(text: "No more polls") // TODO: Translate
            loadingInterface.stopAnimating()
            return false
        }
    }

    @IBAction func loadPollList(sender: AnyObject?) {

        let duration = sender is NSNotification ? 0 : transitionDuration

        UIView.transitionWithView(self.navigationController!.view, duration: duration, options: .TransitionCrossDissolve, animations: { () -> Void in

            // Reset interface
            self.setRefreshMessage(hidden: true)
            self.loadingInterface.startAnimating()
            self.avatarView.image = nil
            self.nameLabel.text = nil
            self.dateLabel.text = nil

            // Reload polls
            self.polls = ParsePollList(type: .VotePublic)
            self.polls.update(completionHandler: { (success, error) -> Void in

                UIView.transitionWithView(self.navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
                    self.showNextPoll()
                    self.handle(error: error, location: "Vote: Load List")
                }, completion: nil)
            })

        }, completion: nil)
    }

    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "Poll Controller":
                pollController = segue.destinationViewController as! PollController
                
            default:
                return
            }
        }
    }

    private func handle(#error: NSError?, location: String?) {
        if let errorToHandle = error {
            FNAnalytics.logError(errorToHandle, location: location ?? "Vote: Error Handler")
            setRefreshMessage(text: errorToHandle.localizedDescription)
        } else {
            setRefreshMessage(text: FNLocalizedUnknownErrorDescription)
        }
        loadingInterface.stopAnimating()
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

    private var tutoPresented = false
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

//        if !tutoPresented {
//            let page1 = EAIntroPage()
//            page1.title = "Welcome to Fashion Now"
//            page1.desc = "This is the Intro"
//            page1.bgImage = UIImage(named: "Photo001.jpg")
//
//            let page2 = EAIntroPage()
//            page2.title = "I created these backgrounds"
//            page2.desc = "See if you like them"
//            page2.bgImage = UIImage(named: "Photo002.jpg")
//
//            let page3 = EAIntroPage()
//            page3.title = "Licence"
//            page3.desc = "All these photos are free to use!"
//            page3.bgImage = UIImage(named: "Photo003.jpg")
//
//            let page4 = EAIntroPage()
//            page4.title = "Effect"
//            page4.desc = "Tilt your device and see what happens"
//            page4.bgImage = UIImage(named: "Photo004.jpg")
//
//            let page5 = EAIntroPage()
//            page5.title = "Ready to go"
//            page5.desc = "Start voting right now"
//            page5.bgImage = UIImage(named: "Photo005.jpg")
//
//            let intro = EAIntroView(frame: fn_tabBarController.view.bounds, andPages: [page1, page2, page3, page4, page5])
//            intro.delegate = self
//            intro.bgViewContentMode = .ScaleToFill
//            intro.showInView(fn_tabBarController.view, animateDuration: 0)
//            statusBarStyle = .LightContent
//            tutoPresented = true
//            UIView.animateWithDuration(0, animations: { () -> Void in
//                self.setNeedsStatusBarAppearanceUpdate()
//            })
//        }
    }

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: EAIntroDelegate

    func introDidFinish(introView: EAIntroView!) {
        statusBarStyle = .Default
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }

    // MARK: PollControllerDelegate

    func pollLoaded(pollController: PollController) {
        UIView.transitionWithView(navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.loadingInterface.stopAnimating()
        }, completion: nil)
    }

    func pollLoadFailed(pollController: PollController, error: NSError) {
        UIView.transitionWithView(navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.handle(error: error, location: "Vote: Poll Load Fail")
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
        FNAnalytics.logVote(index, method: voteMethod)

        ParseVote.sendVote(vote: index, poll: pollController.poll) { (succeeded, error) -> Void in
            if let error = error {
                FNAnalytics.logError(error, location: "Vote: Save")
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
