//
//  FacebookHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class FacebookHelper {

    /**
    Get user picture URL from Facebook

    :param: id Facebook ID of the user

    :param: size Size (in points) of the square picture

    :returns: The URL of the picture
    */
    class func urlForPictureOfUser(id facebookId: String, size avatarSize: Int) -> NSURL? {
        let avatarRealSize = avatarSize * Int(UIScreen.mainScreen().scale)
        let avatarPath = "http://graph.facebook.com/\(facebookId)/picture?height=\(avatarRealSize)&width=\(avatarRealSize)"
        return NSURL(string: avatarPath)
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

    /**
    Only use this if picture was requested along with user info
    */
    var picturePath: String? {
        get {
            let pictureDict = self["picture"] as? [NSObject:AnyObject]
            let dataDict = pictureDict?["data"] as? [NSObject:AnyObject]
            return dataDict?["url"] as? String
        }
    }
}