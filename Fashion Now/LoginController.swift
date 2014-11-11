//
//  LoginController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-08.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginController: UIViewController {

    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func loginButtonPressed(sender: UIButton) {
        PFFacebookUtils.logInWithPermissions(nil) { (user, error) -> Void in
            if let customUser = user as? User {
                FBRequestConnection.startForMeWithCompletionHandler() { (requestConnection, object, error) -> Void in
                    if let graphObject = object as? FBGraphObject {
                        customUser.updateCustomInfo(graphObject: graphObject)
                        customUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                }
            }
        }
    }
}

extension UIViewController {
    
    func needsLogin() -> Bool {
        return false
    }
}
