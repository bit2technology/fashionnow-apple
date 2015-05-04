//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

let VoteNotificationTappedNotificationName = "VoteNotificationTappedNotification"

private let transitionDuration: NSTimeInterval = 0.25

// Action Sheet buttons
private let asReportButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.reportButtonTitle", value: "Report Poll", comment: "Shown when user taps the gear button")
private let asSkipButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.skipButtonTitle", value: "Skip Poll", comment: "Shown when user taps the gear button")
private let asFiltersButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.filtersButtonTitle", value: "Apply Filters", comment: "Shown when user taps the gear button")
private let asLoginButtonTitle = NSLocalizedString("VotePollController.gearButton.actionSheet.loginButtonTitle", value: "Log In", comment: "Shown when user taps the gear button")

// Report alert strings
private let alReportMessage = NSLocalizedString("VotePollController.gearButton.reportAlert.message", value: "Tell us why you want to report this poll", comment: "Shown when user reports a poll")
private let alReportButtonTitle = NSLocalizedString("VotePollController.gearButton.reportAlert.reportButtonTitle", value: "Report", comment: "Shown when user reports a poll")

// Push notification
private let pushAlertAction = NSLocalizedString("VotePollController.pushAlert.viewButtonTitle", value: "View", comment: "Shown when vote push notification received while app is open")

// TODO: Translate
private let rmNoMorePolls = NSLocalizedString("VotePollController.refreshMessage.noMorePolls", value: "No more polls to vote", comment: "Shown when there is no poll to show")
private let rmLoadFail = NSLocalizedString("VotePollController.refreshMessage.pollLoadFail", value: "Ops… Something went wrong. Please, try again.", comment: "Shown when there is no poll to show")

class VotePollController: FNViewController, PollInteractionDelegate, PollLoadDelegate, EAIntroDelegate, UIActionSheetDelegate, UIAlertViewDelegate {

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
        UIView.animateWithDuration(animated ? transitionDuration : 0) { () -> Void in
            for voteButton in [self.leftVoteButton, self.rightVoteButton] {
                voteButton.alpha = (hidden ? 0.2 : 1)
            }
        }
    }
    // Press actions
    @IBAction func voteButtonWillBePressed(sender: UIButton) {
        setVoteButtonsHidden(false, animated: true)
    }
    @IBAction func voteButtonPressed(sender: UIButton) {
        pollController.animateHighlight(index: find([leftVoteButton, rightVoteButton], sender)! + 1, source: .Extern)
    }

    // Message interface with a button to refresh
    @IBOutlet weak var refreshMessage: UILabel!
    @IBOutlet weak var refreshMessageContainer: UIView!
    private func setRefreshMessage(text: String? = nil, hidden: Bool = false) {
        refreshMessage.text = text
        refreshMessageContainer.hidden = hidden
    }

    // Loading interface
    private weak var loadingInterface: UIActivityIndicatorView!

    private func showNextPoll() -> Bool {

        if let firstPollToShow = VotePollController.firstPollId {
            currentPoll = polls.poll(firstPollToShow, remove: true) ?? polls.nextPoll(remove: true)
            VotePollController.firstPollId = nil
        } else {
            currentPoll = polls.nextPoll(remove: true)
        }

        if let pollToShow = currentPoll {

            // Avatar
            if let avatarUrl = pollToShow.createdBy?.avatarURL(size: 33) {
                avatarView.setImageWithURL(avatarUrl, placeholderImage: UIColor.fn_placeholder().fn_image(), usingActivityIndicatorStyle: .White)
            } else {
                avatarView.image = UIColor.fn_placeholder().fn_image()
            }
            // Name
            let createdBy = pollToShow.createdBy
            nameLabel.text = createdBy?.displayName
            // Date
            dateLabel.text = pollToShow.createdAt!.timeAgoSinceNow()

            navigationItem.rightBarButtonItem?.enabled = true

            return true

        } else {
            avatarView.image = nil
            nameLabel.text = nil
            dateLabel.text = nil
            navigationItem.rightBarButtonItem?.enabled = false
            setRefreshMessage(text: rmNoMorePolls)
            loadingInterface.stopAnimating()
            return false
        }
    }

    @IBAction func loadPollList(sender: AnyObject?) {

        let duration = sender is UIButton ? transitionDuration : 0

        UIView.transitionWithView(self.navigationController!.view, duration: duration, options: .TransitionCrossDissolve, animations: { () -> Void in

            // Reset interface
            self.setRefreshMessage(hidden: true)
            self.loadingInterface.startAnimating()
            self.avatarView.image = nil
            self.nameLabel.text = nil
            self.dateLabel.text = nil
            self.navigationItem.rightBarButtonItem?.enabled = false

            // Reload polls
            self.polls = ParsePollList()
            self.polls.update(completionHandler: { (success, error) -> Void in
                UIView.transitionWithView(self.navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
                    if FNAnalytics.logError(error, location: "Vote: Load List") {
                        self.setRefreshMessage(text: error!.domain == FNErrorDomain && error!.code == FNErrorCode.NothingNew.rawValue ? rmNoMorePolls : rmLoadFail)
                        self.loadingInterface.stopAnimating()
                    } else {
                        self.showNextPoll()
                    }
                }, completion: nil)
            })
        }, completion: nil)
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
                let cVaList = getVaList(cArgs)
                let locMessage = NSString(format: locFormat, arguments: cVaList) as String

                // Show notification
                if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {

                    // iOS 8 and above
                    let alert = UIAlertController(title: locTitle, message: locMessage, preferredStyle: .Alert)
                    let defaultHandler: ((UIAlertAction!) -> Void) = { (action) -> Void in
                        self.notificationAlertAction(action.title)
                    }
                    alert.addAction(UIAlertAction(title: FNLocalizedCancelButtonTitle, style: .Cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: pushAlertAction, style: .Default, handler: defaultHandler))
                    fn_tabBarController.presentViewController(alert, animated: true, completion: nil)

                } else {

                    // iOS 7
                    UIAlertView(title: alReportButtonTitle, message: alReportMessage, delegate: self, cancelButtonTitle: FNLocalizedCancelButtonTitle, otherButtonTitles: pushAlertAction).show()
                }
            }
        } else {
            loadPollList(nil)
        }
    }

    private func notificationAlertAction(buttonTitle: String) {
        if buttonTitle == pushAlertAction {
            loadPollList(fn_tabBarController.selectedIndex == 0 ? UIButton() : nil) // Pretend user tapped the refresh button to animate (if vote controller is presented)
            fn_tabBarController.selectedIndex = 0
        }
    }

    // MARK: Gear button

    @IBAction func gearButtonPressed(sender: UIBarButtonItem) {

        // Buttons
        let defaultHandler: ((UIAlertAction!) -> Void) = { (action) -> Void in
            self.actionSheetAction(action.title)
        }
        var actions = [[String:String]]()
        if currentPoll != nil {
            actions.append(["title": asReportButtonTitle, "style": "destructive"])
            actions.append(["title": asSkipButtonTitle])
        }
        // TODO: Add filters
        //actionsheet.addAction(UIAlertAction(title: filtersButtonTitle, style: .Default, handler: defaultHandler))
        if !ParseUser.current().isLogged {
            actions.append(["title": asLoginButtonTitle])
        }
        actions.append(["title": FNLocalizedCancelButtonTitle, "style": "cancel"])

        // Presentation
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {

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
            if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {

                // iOS 8 and above
                let alert = UIAlertController(title: asReportButtonTitle, message: alReportMessage, preferredStyle: .Alert)
                let defaultHandler: ((UIAlertAction!) -> Void) = { (action) -> Void in
                    self.reportAlertAction(action.title, comment: (alert.textFields?.first as? UITextField)?.text)
                }
                alert.addAction(UIAlertAction(title: FNLocalizedCancelButtonTitle, style: .Cancel, handler: defaultHandler))
                alert.addAction(UIAlertAction(title: alReportButtonTitle, style: .Destructive, handler: defaultHandler))
                alert.addTextFieldWithConfigurationHandler(nil)
                presentViewController(alert, animated: true, completion: nil)

            } else {

                // iOS 7
                let alertView = UIAlertView(title: alReportButtonTitle, message: alReportMessage, delegate: self, cancelButtonTitle: FNLocalizedCancelButtonTitle, otherButtonTitles: alReportButtonTitle)
                alertView.alertViewStyle = .PlainTextInput
                alertView.show()
            }

        default:
            break
        }
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.title == asReportButtonTitle {
            reportAlertAction(alertView.buttonTitleAtIndex(buttonIndex), comment: alertView.textFieldAtIndex(0)?.text)
        } else {
            notificationAlertAction(alertView.buttonTitleAtIndex(buttonIndex))
        }
    }

    private func reportAlertAction(buttonTitle: String, comment: String?) {
        switch buttonTitle {
        case alReportButtonTitle:
            // TODO: Report
            pollController.animateHighlight(index: 0, source: .Extern)
        default:
            break
        }
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
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.tabBarItem.selectedImage = UIImage(named: "TabBarIconVoteSelected")

        navigationItem.titleView!.frame.size.width = 9999

        refreshMessageContainer.frame = view.bounds
        refreshMessageContainer.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        view.addSubview(refreshMessageContainer)

        loadingInterface = view.fn_setLoading(background: UIColor.groupTableViewBackgroundColor())

        pollController.interactDelegate = self
        pollController.loadDelegate = self

        // Initializes poll list and adjusts interface
        loadPollList(nil)

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "loadPollList:", name: LoginChangedNotificationName, object: nil)
        notificationCenter.addObserver(self, selector: "notificationReceived:", name: VoteNotificationTappedNotificationName, object: nil)
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
            if FNAnalytics.logError(error, location: "Vote: Poll Load Fail") {
                self.setRefreshMessage(text: rmLoadFail)
                self.loadingInterface.stopAnimating()
            }
        }, completion: nil)
    }

    func pollInteracted(pollController: PollController) {
        setVoteButtonsHidden(true, animated: true)
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

        // FIXME: Test
        var params = ["from": pollController.poll.createdBy!.displayName, "to": ["t6EvTaxkz3"], "poll": pollController.poll.objectId!] as [NSObject : AnyObject]
        let caption = pollController.poll.caption?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if caption?.fn_count > 0 {
            params["caption"] = caption
        }
        PFCloud.callFunctionInBackground("sendPush", withParameters: params) { (result, error) -> Void in
            //FNAnalytics.logError(error, location: "Vote: Send Push")
        }
    }

    func pollDidHighlight(pollController: PollController) {
        UIView.transitionWithView(navigationController!.view, duration: transitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.loadingInterface.startAnimating()
            self.showNextPoll()
        }, completion: nil)
    }
}
