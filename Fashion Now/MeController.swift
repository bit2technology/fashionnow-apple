//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class MeController: UICollectionViewController {

    var myPolls: [ParsePoll]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconMeSelected")

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor.lightGrayColor()
        activityIndicator.startAnimating()
        collectionView?.backgroundView = activityIndicator
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = ParseUser.currentUser().name
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if myPolls == nil {
            let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
            myPollsQuery.includeKey(ParsePollPhotosKey)
            myPollsQuery.whereKey(ParsePollCreatedByKey, equalTo: ParseUser.currentUser())
            myPollsQuery.orderByDescending(ParseObjectCreatedAtKey)
            myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                self.myPolls = objects as? [ParsePoll]
                (self.collectionView?.backgroundView as UIActivityIndicatorView).stopAnimating()
                self.collectionView?.reloadData()
            }
        }
    }

    @IBAction func logOutButtonPressed(snder: AnyObject) {
        ParseUser.logOut()
        (self.tabBarController as TabBarController).selectedIndex = 0
    }

    override func needsLogin() -> Bool {
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let unwrappedId = segue.identifier {

            switch unwrappedId {
            case "Poll Controller":
                (segue.destinationViewController as ResultPollController)
            default:
                return
            }
        }
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myPolls?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poll", forIndexPath: indexPath) as PollCell

        let currentPoll = myPolls![indexPath.item]
        cell.leftImageView.setImageWithURL(NSURL(string: currentPoll.photos!.first!.image!.url), placeholderImage: nil, completed: { (image, error, cache, url) -> Void in
            // Completion
        }, usingActivityIndicatorStyle: .Gray)
        cell.rightImageView.setImageWithURL(NSURL(string: currentPoll.photos!.last!.image!.url), placeholderImage: nil, completed: { (image, error, cache, url) -> Void in
            // Completion
        }, usingActivityIndicatorStyle: .Gray)

        return cell
    }
}

class PollCell: UICollectionViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
}