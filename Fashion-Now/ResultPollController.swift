//
//  ResultPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-12-04.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class ResultPollController: UIViewController {

    var poll: ParsePoll! {
        didSet {
            pollController?.poll = poll
        }
    }

    private var pollController: PollController!

    @IBOutlet weak var captionLabel: UILabel!

    @IBOutlet weak var leftPercentLabel: UILabel!
    @IBOutlet weak var rightPercentLabel: UILabel!

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

        for label in [leftPercentLabel, rightPercentLabel] {
            label.layer.shadowOffset = CGSizeZero
            label.layer.shadowOpacity = 1
            label.layer.shadowRadius = 2
            label.text = nil
        }

        // Date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        navigationItem.title = dateFormatter.stringFromDate(poll.createdAt)
        // Caption
        if let unwrappedCaption = poll.caption {
            captionLabel.text = unwrappedCaption
        } else if let unwrappedTags = poll.tags {
            captionLabel.text = ", ".join(unwrappedTags).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        } else {
            captionLabel.text = ""
        }
        captionLabel.superview?.hidden = countElements(captionLabel.text!) <= 0

        let leftVoteCountQuery = PFQuery(className: ParseVote.parseClassName())
        leftVoteCountQuery.whereKey(ParseVotePollIdKey, equalTo: poll.objectId)
        leftVoteCountQuery.whereKey(ParseVoteVoteKey, equalTo: 1)
        leftVoteCountQuery.countObjectsInBackgroundWithBlock { (leftCount, error) -> Void in
            if error == nil {

                let rightVoteCountQuery = PFQuery(className: ParseVote.parseClassName())
                rightVoteCountQuery.whereKey(ParseVotePollIdKey, equalTo: self.poll.objectId)
                rightVoteCountQuery.whereKey(ParseVoteVoteKey, equalTo: 2)
                rightVoteCountQuery.countObjectsInBackgroundWithBlock { (rightCount, error) -> Void in
                    if error == nil {

                        let totalVoteCount = CGFloat(leftCount + rightCount)
                        if totalVoteCount > 0 {
                            let numberFormatter = NSNumberFormatter()
                            numberFormatter.numberStyle = .PercentStyle
                            self.leftPercentLabel.text = numberFormatter.stringFromNumber(CGFloat(leftCount) / totalVoteCount)
                            self.rightPercentLabel.text = numberFormatter.stringFromNumber(CGFloat(rightCount) / totalVoteCount)
                        }
                    }
                }
            }
        }

        pollController.imageButtonsHidden = true
        pollController.poll = poll
    }

override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Me: Result", block: nil)
    }
}
