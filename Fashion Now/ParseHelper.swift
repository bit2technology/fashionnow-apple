//
//  ParseHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-19.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private func newValueOrNSNull(newValue: AnyObject?) -> AnyObject {
    return (newValue != nil ? newValue! : NSNull())
}

let ParseObjectCreatedAtKey = "createdAt"
let ParseObjectUpdatedAtKey = "updatedAt"
let ParseObjectIdKey = "objectId"

// MARK: - User class

let ParseUserAvatarKey = "avatar"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserNameKey = "name"

public class ParseUser: PFUser, PFSubclassing {

    override public class func load() {
        superclass()?.load()
        registerSubclass()
    }

    var avatar: ParsePhoto? {
        get {
            return self[ParseUserAvatarKey] as? ParsePhoto
        }
        set {
            self[ParseUserAvatarKey] = newValueOrNSNull(newValue)
        }
    }

    var facebookId: String? {
        get {
            return self[ParseUserFacebookIdKey] as? String
        }
        set {
            self[ParseUserFacebookIdKey] = newValueOrNSNull(newValue)
        }
    }

    var gender: String? {
        get {
            return self[ParseUserGenderKey] as? String
        }
        set {
            self[ParseUserGenderKey] = newValueOrNSNull(newValue)
        }
    }

    var name: String? {
        get {
            return self[ParseUserNameKey] as? String
        }
        set {
            self[ParseUserNameKey] = newValueOrNSNull(newValue)
        }
    }

//    var birthday: NSDate? {
//        get {
//            return self[BirthdayKey] as? NSDate
//        }
//    }
//    func setBirthday(#dateString: String?) {
//        if let unwrappedDateString = dateString {
//            
//            let dateFormatter = NSDateFormatter()
//            dateFormatter.dateFormat = "MM/dd/yyyy"
//            dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
//            self[BirthdayKey] = dateFormatter.dateFromString(unwrappedDateString)
//            
//        } else {
//            self[BirthdayKey] = NSNull()
//        }
//    }
}

// MARK: - Poll class

let ParsePollCreatedByKey = "createdBy"
let ParsePollPhotosKey = "photos"
let ParsePollTagsKey = "tags"

public class ParsePoll: PFObject, PFSubclassing {

    override public class func load() {
        superclass()?.load()
        registerSubclass()
    }

    public class func parseClassName() -> String {
        return "Poll"
    }
    
    override init() {
        super.init()
        createdBy = PFUser.currentUser() as? ParseUser
    }

    var createdBy: ParseUser? {
        get {
            return self[ParsePollCreatedByKey] as? ParseUser
        }
        set {
            self[ParsePollCreatedByKey] = newValueOrNSNull(newValue)
        }
    }

    var photos: [ParsePhoto]? {
        get {
            return self[ParsePollPhotosKey] as? [ParsePhoto]
        }
        set {
            self[ParsePollPhotosKey] = newValueOrNSNull(newValue)
        }
    }

    var tags: [String]? {
        get {
            return self[ParsePollTagsKey] as? [String]
        }
        set {
            self[ParsePollTagsKey] = newValueOrNSNull(newValue)
        }
    }
}

// MARK: - Photo class

let ParsePhotoImageKey = "image"
let ParsePhotoUploadedByKey = "uploadedBy"

public class ParsePhoto: PFObject, PFSubclassing {
    
    override public class func load() {
        superclass()?.load()
        registerSubclass()
    }

    public class func parseClassName() -> String {
        return "Photo"
    }
    
    override init() {
        super.init()
        uploadedBy = PFUser.currentUser()
    }

    var image: PFFile? {
        get {
            return self[ParsePhotoImageKey] as? PFFile
        }
        set {
            self[ParsePhotoImageKey] = newValueOrNSNull(newValue)
        }
    }

    var uploadedBy: PFUser? {
        get {
            return self[ParsePhotoUploadedByKey] as? PFUser
        }
        set {
            self[ParsePhotoUploadedByKey] = newValueOrNSNull(newValue)
        }
    }
}
