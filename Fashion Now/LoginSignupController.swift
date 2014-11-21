//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginSignupController: UITableViewController {

    var userObject: FBGraphObject?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func dismiss(sender: UITabBarItem) {
        (self.presentingViewController as TabBarController).willDismissLoginController()
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UIViewController

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Customize interface if there is an user object
        if let unwrappedUser = userObject {
            // Change title and back buttton
            navigationItem.title = NSLocalizedString("SIGNUP_REVIEW_TITLE", value: "Review", comment: "User logged in with a Facebook account and must review his/her information.")
            navigationItem.hidesBackButton = true

            // Fill fields with Facebook information
            emailField.text = unwrappedUser.objectForKey("email") as? String
            nameField.text = unwrappedUser.objectForKey("name") as? String
        }
    }
}