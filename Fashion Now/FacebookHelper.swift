//
//  FacebookHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class FacebookHelper {

    class func urlForPictureOfUser(id facebookId: String, size avatarSize: Int) -> NSURL? {
        let avatarPath = "http://graph.facebook.com/\(facebookId)/picture?height=\(avatarSize)&width=\(avatarSize)"
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

    var picturePath: String? {
        get {
            let pictureDict = self["picture"] as? [NSObject:AnyObject]
            let dataDict = pictureDict?["data"] as? [NSObject:AnyObject]
            return dataDict?["url"] as? String
        }
    }
}