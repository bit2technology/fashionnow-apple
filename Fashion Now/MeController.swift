//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class MeController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconMeSelected")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = ParseUser.currentUser().name
    }

    @IBAction func logOutButtonPressed(snder: AnyObject) {
        ParseUser.logOut()
        (self.tabBarController as TabBarController).selectedIndex = 0
    }

    override func needsLogin() -> Bool {
        return true
    }

    // MARK: UICollectionoViewController

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Test", forIndexPath: indexPath) as UICollectionViewCell

        cell.backgroundColor = UIColor.randomColor()

        return cell
    }
}
