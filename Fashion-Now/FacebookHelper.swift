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
    class func urlForPictureOfUser(id facebookId: String, size avatarSize: Int?) -> NSURL? {
        var avatarPath = "http://graph.facebook.com/\(facebookId)/picture"
        if let unwrappedAvatarSize = avatarSize {
            let avatarRealSize = Int(ceil(CGFloat(unwrappedAvatarSize) * UIScreen.mainScreen().scale))
            avatarPath += "?height=\(avatarRealSize)&width=\(avatarRealSize)"
        }
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
}