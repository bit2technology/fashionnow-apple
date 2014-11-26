//
//  MeController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class MeController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconMeSelected")

        let backgroundLabel = UILabel()
        backgroundLabel.text = "In Construction"
        backgroundLabel.textAlignment = .Center
        backgroundLabel.textColor = UIColor.darkGrayColor()
        tableView.backgroundView = backgroundLabel

        tableView.separatorStyle = .None
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
