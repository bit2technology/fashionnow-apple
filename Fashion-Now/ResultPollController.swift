//
//  ResultPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-12-04.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

private let showAsAbsoluteCountKey = "ResuldtsShowAsAbsoluteCount"
private let cacheResultsKey = "CacheResults"

class ResultPollController: UIViewController, UIActionSheetDelegate, PollLoadDelegate {

    private var pollController: PollController!
    var poll: ParsePoll!

    private weak var activityIndicator: UIActivityIndicatorView!

    var buttonActivity, buttonRefresh, buttonTrash: UIBarButtonItem!

    @IBOutlet weak var dateLabel: UILabel!

    @IBOutlet weak var leftPercentLabel, rightPercentLabel: UILabel!
    private var results = [Int]()
    private var leftCount: Int {
        return results.first ?? 0
    }
    private var rightCount: Int {
        return results.last ?? 0
    }
    /// Track how user wants the results to be shown
    private var showAsAbsoluteCount = NSUserDefaults.standardUserDefaults().boolForKey(showAsAbsoluteCountKey)
    private func setLabelsText() {

        UIView.transitionWithView(leftPercentLabel.superview!.superview!, duration: 0.2, options: .TransitionCrossDissolve, animations: { () -> Void in

            if self.showAsAbsoluteCount {
                self.leftPercentLabel.text = "\(self.leftCount)"
                self.rightPercentLabel.text = "\(self.rightCount)"
            }
            else {
                let totalVoteCount = self.leftCount + self.rightCount == 0 ? 9999 : CGFloat(self.leftCount + self.rightCount)
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = .PercentStyle
                self.leftPercentLabel.text = numberFormatter.stringFromNumber(CGFloat(self.leftCount) / totalVoteCount)
                self.rightPercentLabel.text = numberFormatter.stringFromNumber(CGFloat(self.rightCount) / totalVoteCount)
            }

        }, completion: nil)
    }

    @IBAction func toggleShowAsAbsolute(sender: UITapGestureRecognizer) {
        showAsAbsoluteCount = !showAsAbsoluteCount
        NSUserDefaults.standardUserDefaults().setBool(showAsAbsoluteCount, forKey: showAsAbsoluteCountKey)
        setLabelsText()
    }

    @IBAction func loadResults(sender: UIBarButtonItem?) {

        navigationItem.rightBarButtonItems = [buttonTrash, buttonActivity]

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in

            var error: NSError?

            let leftCount = self.queryForVote(1).countObjects(&error)
            let rightCount = self.queryForVote(2).countObjects(&error)

            dispatch_async(dispatch_get_main_queue(), { () -> Void in

                // TODO: Handle error
                if error != nil {
                    PFAnalytics.fn_trackErrorInBackground(error!, location: "Result: Load Results")
                    FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
                    return
                }

                self.results = [leftCount, rightCount]
                NSUserDefaults.standardUserDefaults().setObject(self.results, forKey: "\(cacheResultsKey)\(self.poll.objectId)")
                self.setLabelsText()

                self.navigationItem.rightBarButtonItems = [self.buttonTrash, self.buttonRefresh]
            })
        })
    }

    @IBAction func deletePoll(sender: UIBarButtonItem) {
        UIActionSheet(title: NSLocalizedString("ResultPollController.deleteSheet.title", value: "Do you really want to delete this poll? This action can't be undone.", comment: "Shown when user is about to delete a poll"), delegate: self, cancelButtonTitle: FNLocalizedCancelButtonTitle, destructiveButtonTitle: NSLocalizedString("ResultPollController.deleteSheet.destructiveButtonTitle", value: "Delete", comment: "Shown when user is about to delete a poll")).showFromBarButtonItem(sender, animated: true)
    }

    private func queryForVote(vote: Int) -> PFQuery {
        return PFQuery(className: ParseVote.parseClassName())
            .whereKey(ParseVotePollIdKey, equalTo: poll.objectId)
            .whereKey(ParseVoteVoteKey, equalTo: vote)
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Percent labels
        for label in [leftPercentLabel, rightPercentLabel] {
            label.layer.shadowOffset = CGSizeZero
            label.layer.shadowOpacity = 1
            label.layer.shadowRadius = 2
            label.text = nil
        }

        // Results cache
        if let cachedResults = NSUserDefaults.standardUserDefaults().arrayForKey("\(cacheResultsKey)\(poll.objectId)") as? [Int] {
            results = cachedResults
            setLabelsText()
        }

        // Bar button items
        let activityIndicatorItem = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicatorItem.frame.size.width = 44
        activityIndicatorItem.startAnimating()
        buttonActivity = UIBarButtonItem(customView: activityIndicatorItem)
        buttonRefresh = UIBarButtonItem(image: UIImage(named: "BarButtonRefresh"), style: .Bordered, target: self, action: "loadResults:")
        buttonTrash = UIBarButtonItem(image: UIImage(named: "BarButtonTrash"), style: .Bordered, target: self, action: "deletePoll:")

        // Navigation item
        navigationItem.titleView!.frame.size.width = 9999
        navigationItem.rightBarButtonItems = [buttonTrash, buttonActivity]

        // Date label
        dateLabel.text = poll.createdAt.timeAgoSinceNow()

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor.grayColor()
        activityIndicator.backgroundColor = UIColor.fn_white()
        activityIndicator.startAnimating()
        activityIndicator.frame = view.bounds
        activityIndicator.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.addSubview(activityIndicator)
        self.activityIndicator = activityIndicator

        pollController.loadDelegate = self
        pollController.poll = poll

        loadResults(nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.fn_trackScreenInBackground("Me: Result", block: nil)
    }

    // MARK: UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.destructiveButtonIndex {

            if Reachability.reachabilityForInternetConnection().isReachable() {
                let activityIndicator = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))

                poll.deleteInBackgroundWithBlock({ (success, error) -> Void in
                    activityIndicator.removeFromSuperview()

                    if error != nil {
                        PFAnalytics.fn_trackErrorInBackground(error, location: "Result: Delete Poll")
                    }

                    if success {
                        NSNotificationCenter.defaultCenter().postNotificationName(FNPollDeletedNotificationName, object: self, userInfo: ["poll": self.poll])
                        self.navigationController?.popViewControllerAnimated(true)
                    } else {
                        FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
                    }
                })
            } else {
                FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
            }
        }
    }

    func pollLoaded(pollController: PollController) {
        activityIndicator?.removeFromSuperview()
    }
    func pollLoadFailed(pollController: PollController, error: NSError) {

    }
}
