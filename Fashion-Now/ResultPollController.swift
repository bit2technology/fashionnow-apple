//
//  ResultPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-12-04.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class ResultPollController: UIViewController {

    private var pollController: PollController!
    var poll: ParsePoll! {
        didSet {
            pollController?.poll = poll
        }
    }

    var buttonActivity: UIBarButtonItem!
    var buttonRefresh: UIBarButtonItem!
    var buttonTrash: UIBarButtonItem!

    @IBOutlet weak var leftPercentLabel: UILabel!
    @IBOutlet weak var rightPercentLabel: UILabel!

    @IBAction func loadResults(sender: UIBarButtonItem?) {

        navigationItem.rightBarButtonItems = [buttonTrash, buttonActivity]

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in

            var error: NSError?

            let leftCount = self.queryForVote(1).countObjects(&error)
            let rightCount = self.queryForVote(2).countObjects(&error)

            dispatch_async(dispatch_get_main_queue(), { () -> Void in

                self.leftPercentLabel.text = "\(leftCount)"
                self.rightPercentLabel.text = "\(rightCount)"

                self.navigationItem.rightBarButtonItems = [self.buttonTrash, self.buttonRefresh]
            })
        })
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

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.frame.size.width = 44
        activityIndicator.startAnimating()
        buttonActivity = UIBarButtonItem(customView: activityIndicator)
        buttonRefresh = UIBarButtonItem(image: UIImage(named: "BarButtonRefresh"), style: .Bordered, target: self, action: "loadResults:")
        buttonTrash = UIBarButtonItem(image: UIImage(named: "BarButtonTrash"), style: .Bordered, target: nil, action: nil)

        navigationItem.titleView?.frame.size.width = 9999

        navigationItem.rightBarButtonItems = [buttonTrash, buttonActivity]

        for label in [leftPercentLabel, rightPercentLabel] {
            label.layer.shadowOffset = CGSizeZero
            label.layer.shadowOpacity = 1
            label.layer.shadowRadius = 2
            label.text = nil
        }

//        let leftVoteCountQuery = PFQuery(className: ParseVote.parseClassName())
//        leftVoteCountQuery.whereKey(ParseVotePollIdKey, equalTo: poll.objectId)
//        leftVoteCountQuery.whereKey(ParseVoteVoteKey, equalTo: 1)
//        leftVoteCountQuery.countObjectsInBackgroundWithBlock { (leftCount, error) -> Void in
//            if error == nil {
//
//                let rightVoteCountQuery = PFQuery(className: ParseVote.parseClassName())
//                rightVoteCountQuery.whereKey(ParseVotePollIdKey, equalTo: self.poll.objectId)
//                rightVoteCountQuery.whereKey(ParseVoteVoteKey, equalTo: 2)
//                rightVoteCountQuery.countObjectsInBackgroundWithBlock { (rightCount, error) -> Void in
//                    if error == nil {
//
//                        let totalVoteCount = CGFloat(leftCount + rightCount)
//                        if totalVoteCount > 0 {
//                            let numberFormatter = NSNumberFormatter()
//                            numberFormatter.numberStyle = .PercentStyle
//                            self.leftPercentLabel.text = numberFormatter.stringFromNumber(CGFloat(leftCount) / totalVoteCount)
//                            self.rightPercentLabel.text = numberFormatter.stringFromNumber(CGFloat(rightCount) / totalVoteCount)
//                        }
//                    }
//                }
//            }
//        }

        loadResults(nil)

        pollController.imageButtonsHidden = true
        pollController.poll = poll
    }

override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Me: Result", block: nil)
    }
}
