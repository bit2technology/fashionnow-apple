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

        downloadPollList(update: false)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = ParseUser.currentUser().name
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func loginChanged(notification: NSNotification) {
        downloadPollList(update: false)
    }

    private func downloadPollList(#update: Bool) {

        myPolls = nil
        (collectionView?.backgroundView as UIActivityIndicatorView).startAnimating()
        collectionView?.reloadData()

        let currentUser = ParseUser.currentUser()!
        if PFAnonymousUtils.isLinkedWithUser(currentUser) {
            return
        }

        let myPollsQuery = PFQuery(className: ParsePoll.parseClassName())
        myPollsQuery.includeKey(ParsePollPhotosKey)
        myPollsQuery.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
        myPollsQuery.orderByDescending(ParseObjectCreatedAtKey)
        myPollsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            self.myPolls = objects as? [ParsePoll]
            (self.collectionView?.backgroundView as UIActivityIndicatorView).stopAnimating()
            self.collectionView?.reloadSections(NSIndexSet(index: 0))
        }
    }

    @IBAction func logOutButtonPressed(snder: AnyObject) {
        ParseUser.logOut()
        NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
        tabBarController!.selectedIndex = 0
    }

    override func needsLogin() -> Bool {
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let unwrappedId = segue.identifier {

            switch unwrappedId {
            case "Result Controller":
                let idx = collectionView!.indexPathForCell(sender as UICollectionViewCell)!.item
                (segue.destinationViewController as ResultPollController).poll = myPolls![idx]
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