//
//  FacebookHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private let FacebookAvatarURLKey = "facebookAvatarURL"

class FacebookHelper {

    // MARK: Avatar

    class var cachedAvatarPath: String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(FacebookAvatarURLKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: FacebookAvatarURLKey)
        }
    }

    class func updateCachedAvatarPathInBackground() {
        let avatarSize = Int(64 * UIScreen.mainScreen().scale)
        FBRequestConnection.startWithGraphPath("me?fields=picture.height(\(avatarSize)).width(\(avatarSize)).redirect(false)") { (connection, result, error) -> Void in
            if error == nil {
                self.cachedAvatarPath = (result as? FBGraphObject)?.picturePath
            } else {
                // TODO: Better error handling
                UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
            }
        }
    }
}

extension FBGraphObject {

    var email: String? {
        get {
            return self["email"] as? String
        }
    }

    var first_name: String? {
        get {
            return self["first_name"] as? String
        }
    }

    var gender: String? {
        get {
            return self["gender"] as? String
        }
    }

    var objectId: String? {
        get {
            return self["id"] as? String
        }
    }

    var picturePath: String? {
        get {
            let pictureDict = self["picture"] as? [NSObject:AnyObject]
            let dataDict = pictureDict?["data"] as? [NSObject:AnyObject]
            return dataDict?["url"] as? String
        }
    }
}