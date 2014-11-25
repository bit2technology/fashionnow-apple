//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class MeController: UIViewController/*, UITableViewDataSource, UITableViewDelegate*/ {

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = ParseUser.currentUser().name
    }

    @IBAction func logOut(snder: UITabBarItem) {
        ParseUser.logOut()
        (self.tabBarController as TabBarController).selectedIndex = 0
    }

    override func needsLogin() -> Bool {
        return true
    }

    // MARK: UITableViewController
}
