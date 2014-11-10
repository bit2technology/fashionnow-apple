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

            println("teste")
            FBRequestConnection.startForMeWithCompletionHandler() { (requestConnection, object, error) -> Void in

                println("objec:\(object)")
                user.email = (object as FBGraphObject).objectForKey("email") as String
                user.saveInBackgroundWithBlock(nil)
            }
        }
    }
}
