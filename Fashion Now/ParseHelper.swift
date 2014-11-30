//
//  ParseHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-19.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

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
            self[ParseUserAvatarKey] = newValue ?? NSNull()
        }
    }

    var birthday: String? {
        get {
            return self[ParseUserBirthdayKey] as? String
        }
        set {
            self[ParseUserBirthdayKey] = newValue ?? NSNull()
        }
    }
    func birthdayDate(format: String = ParseUserBirthdayDateFormat) -> NSDate? {
        if let unwrappedBirthday = birthday {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = format
            return dateFormatter.dateFromString(unwrappedBirthday)
        }
        return nil
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
            self[ParseUserFacebookIdKey] = newValue ?? NSNull()
        }
    }

    var gender: String? {
        get {
            return self[ParseUserGenderKey] as? String
        }
        set {
            self[ParseUserGenderKey] = newValue ?? NSNull()
        }
    }

    var location: String? {
        get {
            return self[ParseUserLocationKey] as? String
        }
        set {
            self[ParseUserLocationKey] = newValue ?? NSNull()
        }
    }

    var name: String? {
        get {
            return self[ParseUserNameKey] as? String
        }
        set {
            self[ParseUserNameKey] = newValue ?? NSNull()
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

    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL(user: user)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        uploadedBy = user
    }

    var image: PFFile? {
        get {
            return self[ParsePhotoImageKey] as? PFFile
        }
        set {
            self[ParsePhotoImageKey] = newValue ?? NSNull()
        }
    }

    var uploadedBy: ParseUser? {
        get {
            return self[ParsePhotoUploadedByKey] as? ParseUser
        }
        set {
            self[ParsePhotoUploadedByKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        get {
            return image != nil && uploadedBy != nil
        }
    }
}

// MARK: - Poll class

let ParsePollCaptionKey = "caption"
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
    
    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL(user: user)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        createdBy = user
    }

    var caption: String? {
        get {
            return self[ParsePollCaptionKey] as? String
        }
        set {
            self[ParsePollCaptionKey] = newValue ?? NSNull()
        }
    }

    var createdBy: ParseUser? {
        get {
            return self[ParsePollCreatedByKey] as? ParseUser
        }
        set {
            self[ParsePollCreatedByKey] = newValue ?? NSNull()
        }
    }

    var photos: [ParsePhoto]? {
        get {
            return self[ParsePollPhotosKey] as? [ParsePhoto]
        }
        set {
            self[ParsePollPhotosKey] = newValue ?? NSNull()
        }
    }

    var tags: [String]? {
        get {
            return self[ParsePollTagsKey] as? [String]
        }
        set {
            self[ParsePollTagsKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

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
            return createdBy != nil
        }
    }
}

// MARK: - Vote class

let ParseVoteByKey = "voteBy"
let ParseVotePollIdKey = "pollId"
let ParseVoteVoteKey = "vote"

public class ParseVote: PFObject, PFSubclassing {

    override public class func load() {
        superclass()?.load()
        registerSubclass()
    }

    public class func parseClassName() -> String {
        return "Vote"
    }

    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL()
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        voteBy = user
    }

    var pollId: String? {
        get {
            return self[ParseVotePollIdKey] as? String
        }
        set {
            self[ParseVotePollIdKey] = newValue ?? NSNull()
        }
    }

    var vote: NSNumber? {
        get {
            return self[ParseVoteVoteKey] as? NSNumber
        }
        set {
            self[ParseVoteVoteKey] = newValue ?? NSNull()
        }
    }

    var voteBy: ParseUser? {
        get {
            return self[ParseVoteByKey] as? ParseUser
        }
        set {
            self[ParseVoteByKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        get {
            return pollId != nil && vote != nil && voteBy != nil
        }
    }
}

