//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

let VoteNotificationTappedNotificationName = "VoteNotificationTappedNotification"

private let tutorialShownKey = "tutorialVote1"
private var tutorialShown = NSUserDefaults.standardUserDefaults().boolForKey(tutorialShownKey) {
    didSet {
        NSUserDefaults.standardUserDefaults().setBool(tutorialShown, forKey: tutorialShownKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

// Action Sheet buttons
private let asBlockButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.blockButtonTitle", value: "Block User", comment: "Shown when user taps the gear button")
private let asReportButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.reportButtonTitle", value: "Report Poll", comment: "Shown when user taps the gear button")
private let asSkipButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.skipButtonTitle", value: "Skip Poll", comment: "Shown when user taps the gear button")
private let asFiltersButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.filtersButtonTitle", value: "Apply Filters", comment: "Shown when user taps the gear button")
private let asLoginButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.loginButtonTitle", value: "Log In", comment: "Shown when user taps the gear button")

// Refresh message
private let rmNoMorePolls = NSLocalizedString("VotePollController.refreshMessage.noMorePolls", value: "No more polls to vote", comment: "Shown when there is no poll to show")
private let rmLoadFail = NSLocalizedString("VotePollController.refreshMessage.pollLoadFail", value: "Ops… Something went wrong. Please, try again.", comment: "Shown when there is no poll to show")

class VotePollController: FNViewController, PollInteractionDelegate, PollLoadDelegate, UIActionSheetDelegate {

    /// This is the firs poll to be shown. Used to open from Notification or URL.
    static var firstPollId: String?

    /// Parameters to load polls. Used to apply filters.
    private var parameters = ParsePollList.Parameters()

    /// Poll list to be voted.
    private var polls = ParsePollList()

    /// Store if there is a poll to be voted.
    private weak var currentPoll: ParsePoll? {
        willSet {
            if let newPoll = newValue {
                pollController.poll = newPoll
            }
        }
    }

    /// Reference to the poll controller.
    private weak var pollController: PollController!

    /// Change the status bar style (needs to call update method).
    private var statusBarStyle = UIStatusBarStyle.Default

    // Navigation bar items
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel, dateLabel: UILabel!

    // Vote buttons
    @IBOutlet weak var leftVoteButton, rightVoteButton: UIButton!
    private func setVoteButtonsHidden(hidden: Bool, animated: Bool) {
        UIView.animateWithDuration(animated ? FNTransitionDuration : 0, animations: { () -> Void in
            for voteButton in [self.leftVoteButton, self.rightVoteButton] {
                voteButton.alpha = (hidden ? 0 : 1)
            }
        })
    }
    @IBAction func voteButtonPressed(sender: UIButton) {
        pollController.animateHighlight(index: find([leftVoteButton, rightVoteButton], sender)! + 1, source: .Extern)
    }

    // Message interface with a button to refresh
    @IBOutlet weak var refreshMessage: UILabel!
    @IBOutlet weak var refreshMessageContainer: UIView!

    // Loading interface
    private weak var loadingInterface: UIActivityIndicatorView!

    private func showNextPoll() -> Bool {

        if let firstPollToShow = VotePollController.firstPollId {
            currentPoll = polls.remove(id: firstPollToShow) ?? polls.removeNext()
            VotePollController.firstPollId = nil
        } else {
            currentPoll = polls.removeNext()
        }

        if let pollToShow = currentPoll {

            // Avatar
            let placeholderImage = UIColor.fn_placeholder().fn_image()
            if let avatarUrl = pollToShow.createdBy?.avatarURL(size: 33) {
                avatarView.setImageWithURL(avatarUrl, placeholderImage: placeholderImage, usingActivityIndicatorStyle: .White)
            } else {
                avatarView.image = placeholderImage
            }
            // Name
            nameLabel.text = pollToShow.createdBy?.displayName
            // Date
            if let createdAt = pollToShow.createdAt where createdAt.hoursFrom(NSDate()) > -24 {
                dateLabel.text = createdAt.timeAgoSinceNow()
            } else {
                dateLabel.text = NSLocalizedString("VotePollController.createdAt.moreThanOneDayAgo", value: "More than one day ago", comment: "Shown when current poll was created more than 24h ago")
            }

            navigationItem.rightBarButtonItem?.enabled = true

            return true

        } else {
            avatarView.image = nil
            nameLabel.text = nil
            dateLabel.text = nil
            navigationItem.rightBarButtonItem?.enabled = false
            refreshMessage.text = rmNoMorePolls
            refreshMessageContainer.hidden = false
            loadingInterface.hidden = true
            return false
        }
    }

    @IBAction func refreshButtonPressed(sender: UIButton) {
        loadPollList(refreshMessage.text != rmNoMorePolls, animated: true)
    }

    func loginDidChange(sender: NSNotification) {
        loadPollList(true, animated: false)
    }

    private func loadPollList(clear: Bool, animated: Bool) {

        navigationController!.view.fn_transition(animated, changes: { () -> Void in

            // Reset interface
            self.refreshMessageContainer.hidden = true
            self.loadingInterface.hidden = false
            self.avatarView.image = nil
            self.nameLabel.text = nil
            self.dateLabel.text = nil
            self.navigationItem.rightBarButtonItem?.enabled = false

            // Reload polls
            if clear {
                self.polls = ParsePollList()
            }
            self.polls.update(completionHandler: { (success, error) -> Void in
                self.navigationController!.view.fn_transition(true, changes: { () -> Void in
                    if FNAnalytics.logError(error, location: "Vote: Load List") {
                        // If error is RequestTooOften, do not change the message
                        if error!.domain != FNErrorDomain || error!.code != FNErrorCode.RequestTooOften.rawValue {
                            self.refreshMessage.text = error!.domain == FNErrorDomain && error!.code == FNErrorCode.NothingNew.rawValue ? rmNoMorePolls : rmLoadFail
                        }
                        self.refreshMessageContainer.hidden = false
                        self.loadingInterface.hidden = true
                    } else {
                        self.showNextPoll()
                    }
                })
            })
        })
    }

    func notificationReceived(sender: NSNotification) {

        if UIApplication.sharedApplication().applicationState == .Active {
            let alert = sender.userInfo?["aps"]?["alert"] as? [String:AnyObject]
            if let title = alert?["title-loc-key"] as? String, let format = alert?["loc-key"] as? String, let args = alert?["loc-args"] as? [String] {

                // Title
                let locTitle = NSLocalizedString(title, comment: "")

                // Message
                let locFormat = NSLocalizedString(format, comment: "")
                var cArgs = [CVarArgType]()
                for arg in args {
                    cArgs.append(Unmanaged<AnyObject>.passUnretained(arg).toOpaque())
                }
                let locMessage = String(format: locFormat, arguments: cArgs)

                // Show notification
                let alert = SDCAlertController(title: locTitle, message: locMessage, preferredStyle: .Alert)
                alert.addAction(SDCAlertAction(title: FNLocalizedCancelButtonTitle, style: .Cancel, handler: nil))
                alert.addAction(SDCAlertAction(title: NSLocalizedString("VotePollController.pushAlert.viewButtonTitle", value: "View", comment: "Shown when vote push notification received while app is open"), style: .Default, handler: { (action) -> Void in
                    self.loadPollList(true, animated: self.fn_tabBarController.selectedIndex == 0)
                    self.fn_tabBarController.selectedIndex = 0
                }))
                alert.presentWithCompletion(nil)
            }
        } else {
            loadPollList(true, animated: false)
            fn_tabBarController.selectedIndex = 0
        }
    }

    private func registerPushNotification() {
        let application = UIApplication.sharedApplication()
        if application.respondsToSelector("registerUserNotificationSettings:") {
            // Register for Push Notitications, if running iOS 8 and later
            let settings = UIUserNotificationSettings(forTypes:.Alert | .Badge | .Sound, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }
    }

    // MARK: Gear button

    @IBAction func gearButtonPressed(sender: UIBarButtonItem) {

        // Buttons
        let defaultHandler: ((UIAlertAction!) -> Void) = { (action) -> Void in
            self.actionSheetAction(action.title)
        }
        var actions = [[String:String]]()
        actions.append(["title": asBlockButtonTitle, "style": "destructive"])
        actions.append(["title": asReportButtonTitle])
        actions.append(["title": asSkipButtonTitle])
        // TODO: Add filters
        //actions.append(["title": filtersButtonTitle])
        if !ParseUser.current().isLogged {
            actions.append(["title": asLoginButtonTitle])
        }
        actions.append(["title": FNLocalizedCancelButtonTitle, "style": "cancel"])

        // Presentation
        if NSClassFromString("UIAlertController") != nil {

            // iOS 8 and above
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            for action in actions {
                var style = UIAlertActionStyle.Default
                if let styleStr = action["style"] {
                    if styleStr == "destructive" {
                        style = .Destructive
                    } else if styleStr == "cancel" {
                        style = .Cancel
                    }
                }
                actionSheet.addAction(UIAlertAction(title: action["title"]!, style: style, handler: defaultHandler))
            }
            actionSheet.popoverPresentationController?.barButtonItem = sender
            presentViewController(actionSheet, animated: true, completion: nil)

        } else {

            // iOS 7
            let actionSheet = UIActionSheet()
            for action in actions {
                let idx = actionSheet.addButtonWithTitle(action["title"]!)
                if let styleStr = action["style"] {
                    if styleStr == "destructive" {
                        actionSheet.destructiveButtonIndex = idx
                    } else if styleStr == "cancel" {
                        actionSheet.cancelButtonIndex = idx
                    }
                }
            }
            actionSheet.delegate = self
            actionSheet.showFromBarButtonItem(sender, animated: true)
        }
    }

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        actionSheetAction(actionSheet.buttonTitleAtIndex(buttonIndex))
    }

    private func actionSheetAction(buttonTitle: String) {
        switch buttonTitle {

        case asSkipButtonTitle:
            pollController.animateHighlight(index: 0, source: .Extern)

        case asLoginButtonTitle:
            (tabBarController as! TabBarController).presentLoginController()

        case asReportButtonTitle:
            let alert = SDCAlertController(title: asReportButtonTitle, message: NSLocalizedString("VotePollController.gearButton.reportAlert.message", value: "Tell us why you want to report this poll", comment: "Shown when user reports a poll"), preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(SDCAlertAction(title: FNLocalizedCancelButtonTitle, style: .Cancel, handler: nil))
            alert.addAction(SDCAlertAction(title: NSLocalizedString("VotePollController.gearButton.reportAlert.reportButtonTitle", value: "Report", comment: "Shown when user reports a poll"), style: .Default, handler: { (action) -> Void in
                ParseReport.sendReport(self.currentPoll!, comment: alert.textFieldAtIndex(0)?.text, block: { (succeeded, error) -> Void in
                    FNAnalytics.logError(error, location: "Vote: Report Poll")
                })
                self.pollController.animateHighlight(index: 0, source: .Extern)
            }))
            alert.presentWithCompletion(nil)

        case asBlockButtonTitle:
            let messageWithArgument = NSString(format: NSLocalizedString("VotePollController.gearButton.blockAlert.message", value: "Are you sure you want to block %@? You won’t see any poll from this user.", comment: "Shown when user blocks a user"), currentPoll!.createdBy!.displayName) as String
            let alert = SDCAlertController(title: asBlockButtonTitle, message: messageWithArgument, preferredStyle: .Alert)
            alert.addAction(SDCAlertAction(title: FNLocalizedCancelButtonTitle, style: .Cancel, handler: nil))
            alert.addAction(SDCAlertAction(title: NSLocalizedString("VotePollController.gearButton.blockAlert.blockButtonTitle", value: "Block", comment: "Shown when user blocks a user"), style: .Default, handler: { (action) -> Void in
                self.navigationController!.view.fn_transition(true, changes: { () -> Void in
                    self.loadingInterface.hidden = false
                    self.avatarView.image = nil
                    self.nameLabel.text = nil
                    self.dateLabel.text = nil
                    self.navigationItem.rightBarButtonItem?.enabled = false
                }, completion: { (finished) -> Void in
                    ParseBlock.block(self.currentPoll!.createdBy!, block: { (succeeded, error) -> Void in
                        FNAnalytics.logError(error, location: "Vote: Block User")
                        self.loadPollList(true, animated: true)
                    })
                })
            }))
            alert.presentWithCompletion(nil)

        default:
            break
        }
    }

    // MARK: UIViewController

    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "Show Profile" && currentPoll?.createdBy == nil {
            return false
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "Poll Controller":
                pollController = segue.destinationViewController as! PollController
            case "Show Profile":
                let profileController = segue.destinationViewController as! ProfileController
                profileController.user = currentPoll!.createdBy!
                
            default:
                return
            }
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView!.frame.size.width = 9999

        refreshMessageContainer.frame = view.bounds
        refreshMessageContainer.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        view.addSubview(refreshMessageContainer)

        loadingInterface = view.fn_setLoading(background: UIColor.groupTableViewBackgroundColor())

        pollController.interactDelegate = self
        pollController.loadDelegate = self

        // Initializes poll list and adjusts interface
        loadPollList(false, animated: false)

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "loginDidChange:", name: LoginChangedNotificationName, object: nil)
        notificationCenter.addObserver(self, selector: "notificationReceived:", name: VoteNotificationTappedNotificationName, object: nil)

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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !tutorialShown {

            let alertWelcome = fn_alertController(UIImage(named: "TutorialWelcome.jpg")!)
            let alertVote = fn_alertController(UIImage(named: "TutorialVote.jpg")!)
            let alertAnalytics = SDCAlertController(title: NSLocalizedString("VotePollController.tutorial.analytics.title", value: "Send Usage Data?", comment: "Alert asking to user for usage statistics"), message: NSLocalizedString("VotePollController.tutorial.analytics.message", value: "Send usage data in order to help to improve Fashion Now. These informations won’t be used to identify or contact you.", comment: "Alert asking to user for usage statistics"), preferredStyle: .Alert)

            alertWelcome.addAction(SDCAlertAction(title: NSLocalizedString("VotePollController.tutorial.welcome.enter", value: "Enter", comment: "Dismiss welcome alert button title"), style: .Recommended, handler: { (action) -> Void in
                alertVote.presentWithCompletion(nil)
            }))
            alertVote.addAction(SDCAlertAction(title: FNLocalizedGotItButtonTitle, style: .Recommended, handler: { (action) -> Void in
                alertAnalytics.presentWithCompletion(nil)
            }))
            alertAnalytics.addAction(SDCAlertAction(title: NSLocalizedString("VotePollController.tutorial.analytics.no", value: "No, Thanks", comment: "Alert asking to user for usage statistics"), style: .Cancel, handler: { (action) -> Void in
                GAI.sharedInstance().optOut = true
                self.registerPushNotification()
            }))
            alertAnalytics.addAction(SDCAlertAction(title: NSLocalizedString("VotePollController.tutorial.analytics.yes", value: "Send", comment: "Alert asking to user for usage statistics"), style: .Default, handler: { (action) -> Void in
                GAI.sharedInstance().optOut = false
                self.registerPushNotification()
            }))
            
            alertWelcome.presentWithCompletion(nil)

            tutorialShown = true
        }
    }

//    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
//        return .Fade
//    }
//
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return statusBarStyle
//    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: EAIntroDelegate

//    func introDidFinish(introView: EAIntroView!) {
//        statusBarStyle = .Default
//        UIView.animateWithDuration(0.5, animations: { () -> Void in
//            self.setNeedsStatusBarAppearanceUpdate()
//        })
//    }

    // MARK: PollControllerDelegate

    func pollLoaded(pollController: PollController) {
        view.fn_transition(true, changes: { () -> Void in
            self.setVoteButtonsHidden(false, animated: false)
            self.loadingInterface.hidden = true
        }, completion: { (finished) -> Void in
            for gesture in [self.pollController.tap, self.pollController.doubleTap, self.pollController.drager] {
                gesture.enabled = true
            }
            for button in [self.leftVoteButton, self.rightVoteButton] {
                button.userInteractionEnabled = true
            }
        })
    }

    func pollLoadFailed(pollController: PollController, error: NSError) {
        view.fn_transition(true, changes: { () -> Void in
            if FNAnalytics.logError(error, location: "Vote: Poll Load Fail") {
                self.refreshMessage.text = rmLoadFail
                self.refreshMessageContainer.hidden = false
                self.loadingInterface.hidden = true
            }
        })
    }

    func pollInteractionBegan(pollController: PollController) {
        setVoteButtonsHidden(true, animated: true)
    }

    func pollInteractionEnded(pollController: PollController) {
        setVoteButtonsHidden(false, animated: true)
    }

    func pollWillHighlight(pollController: PollController, index: Int, source: PollController.HighlightSource) {

        var voteMethod = "Button"
        if source == .DoubleTap {
            voteMethod = "Double Tap"
        } else if source == .Drag {
            voteMethod = "Drag"
        }
        FNAnalytics.logVote(index, method: voteMethod)

        ParseVote.sendVote(vote: index, poll: currentPoll!) { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "Vote: Save")
        }

        for gesture in [pollController.tap, pollController.doubleTap, pollController.drager] {
            gesture.enabled = false
        }
        for button in [leftVoteButton, rightVoteButton] {
            button.userInteractionEnabled = false
        }
    }

    func pollDidHighlight(pollController: PollController) {
        navigationController!.view.fn_transition(true, changes: { () -> Void in
            self.loadingInterface.hidden = false
            self.showNextPoll()
        })
    }
}
