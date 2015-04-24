//
//  FacebookHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class FacebookUser {

    let email, first_name, gender, objectId: String?

    init(graphObject: [String: String]) {
        email = graphObject["email"]
        first_name = graphObject["first_name"]
        gender = graphObject["gender"]
        objectId = graphObject["id"]
    }

    convenience init(id: String) {
        self.init(graphObject: ["id": id])
    }

    func avatarUrl(size avatarSize: CGFloat?) -> NSURL? {
        if let facebookId = objectId {
            var avatarPath = "http://graph.facebook.com/\(facebookId)/picture"
            if let unwrappedAvatarSize = avatarSize {
                let avatarRealSize = Int(ceil(unwrappedAvatarSize * UIScreen.mainScreen().scale))
                avatarPath += "?height=\(avatarRealSize)&width=\(avatarRealSize)"
            }
            return NSURL(string: avatarPath)
        } else {
            return nil
        }
    }

    class func getCurrent(completion: (user: FacebookUser?, error: NSError?) -> Void) {

        // Get information from Facebook
        FBSDKGraphRequest(graphPath: "me?fields=id,first_name,email,gender", parameters: nil).startWithCompletionHandler { (requestConnection, object, error) -> Void in

            let user: FacebookUser?
            if let graphObject = object as? [String: String] {
                user = FacebookUser(graphObject: graphObject)
            } else {
                user = nil
            }

            completion(user: user, error: error)
        }
    }
}