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

class FacebookUser {

    let email, first_name, gender, objectId: String?

    init(graphObject: AnyObject?) {
        email = graphObject?["email"] as? String
        first_name = graphObject?["first_name"] as? String
        gender = graphObject?["gender"] as? String
        objectId = graphObject?["id"] as? String
    }
}