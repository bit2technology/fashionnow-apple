//
//  ParseHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-19.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private func newValueOrNSNull(newValue: AnyObject?) -> AnyObject {
    return newValue ?? NSNull()
}

let ParseObjectCreatedAtKey = "createdAt"
let ParseObjectUpdatedAtKey = "updatedAt"
let ParseObjectIdKey = "objectId"

// MARK: - User class

let ParseUserAvatarKey = "avatar"
let ParseUserBirthdayKey = "birthday"
let ParseUserBirthdayDateFormat = "yyyy-MM-dd"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserLocationKey = "location"
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

    var birthday: String? {
        get {
            return self[ParseUserBirthdayKey] as? String
        }
        set {
            self[ParseUserBirthdayKey] = newValueOrNSNull(newValue)
        }
    }
    func birthdayDate(format: String = ParseUserBirthdayDateFormat) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return self.birthday != nil ? dateFormatter.dateFromString(birthday!) : nil
    }
    func setBirthday(#date: NSDate) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = ParseUserBirthdayDateFormat
        birthday = dateFormatter.stringFromDate(date)
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

    var location: String? {
        get {
            return self[ParseUserLocationKey] as? String
        }
        set {
            self[ParseUserLocationKey] = newValueOrNSNull(newValue)
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
        let currentUser = PFUser.currentUser() as ParseUser
        let defaultACL = PFACL(user: currentUser)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        createdBy = currentUser
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





    var isValid: Bool {
        get {
            if photos == nil {
                return false
            }
            for photo in photos! {
                if photo.isValid != true {
                    return false
                }
            }
            return true
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
        let currentUser = PFUser.currentUser() as ParseUser
        let defaultACL = PFACL(user: currentUser)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        uploadedBy = currentUser
    }

    var image: PFFile? {
        get {
            return self[ParsePhotoImageKey] as? PFFile
        }
        set {
            self[ParsePhotoImageKey] = newValueOrNSNull(newValue)
        }
    }

    var uploadedBy: ParseUser? {
        get {
            return self[ParsePhotoUploadedByKey] as? ParseUser
        }
        set {
            self[ParsePhotoUploadedByKey] = newValueOrNSNull(newValue)
        }
    }






    var isValid: Bool {
        get {
            return image != nil && uploadedBy != nil
        }
    }
}
