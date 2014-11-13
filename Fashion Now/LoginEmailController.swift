//
//  LoginEmailController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-12.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginEmailController: UITableViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func loginButtonPressed(sender: UIButton) {
        usernameField.enabled = false
        passwordField.enabled = false
        sender.enabled = false
        PFUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user, error) -> Void in
            if user != nil {
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle: NSLocalizedString("LOGIN_EMAIL_ERROR_OK", comment: "Log in with e-mail error cancel button title")).show()
                self.usernameField.enabled = true
                self.passwordField.enabled = true
                sender.enabled = true
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let tableViewHeaderHeight = view.bounds.height - 460
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: tableViewHeaderHeight))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        usernameField.becomeFirstResponder()
    }
}
