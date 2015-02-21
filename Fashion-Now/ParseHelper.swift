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

// MARK: - Installation class

let ParseInstallationUserIdKey = "userId"

public class ParseInstallation: PFInstallation, PFSubclassing {

    var userId: String? {
        get {
            return self[ParseInstallationUserIdKey] as? String
        }
        set {
            self[ParseInstallationUserIdKey] = newValue ?? NSNull()
        }
    }
}

// MARK: - User class

let ParseUserAvatarKey = "avatar"
let ParseUserBirthdayKey = "birthday"
let ParseUserBirthdayDateFormat = "yyyy-MM-dd"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserHasPassword = "hasPassword"
let ParseUserLocationKey = "location"
let ParseUserNameKey = "name"

public class ParseUser: PFUser, PFSubclassing {

    var avatar: ParsePhoto? {
        get {
            return self[ParseUserAvatarKey] as? ParsePhoto
        }
        set {
            self[ParseUserAvatarKey] = newValue ?? NSNull()
        }
    }

//    var birthday: String? {
//        get {
//            return self[ParseUserBirthdayKey] as? String
//        }
//        set {
//            self[ParseUserBirthdayKey] = newValue ?? NSNull()
//        }
//    }
//    func birthdayDate(format: String = ParseUserBirthdayDateFormat) -> NSDate? {
//        if let unwrappedBirthday = birthday {
//            let dateFormatter = NSDateFormatter()
//            dateFormatter.dateFormat = format
//            return dateFormatter.dateFromString(unwrappedBirthday)
//        }
//        return nil
//    }
//    func setBirthday(#date: NSDate) {
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = ParseUserBirthdayDateFormat
//        birthday = dateFormatter.stringFromDate(date)
//    }

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

    var hasPassword: Bool? {
        get {
            return self[ParseUserHasPassword] as? Bool
        }
        set {
            self[ParseUserHasPassword] = newValue ?? NSNull()
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

public class ParsePublicVotePollList: Printable, DebugPrintable {

    private var polls = [ParsePoll]()
    private let pollsToVoteQuery: PFQuery

    var count: Int {
        get {
            return polls.count
        }
    }

    public var description: String {
        get {
            return polls.description
        }
    }
    public var debugDescription: String {
        get {
            return polls.debugDescription
        }
    }

    init() {
        let currentUser = ParseUser.currentUser()
        let pollsToVoteQueryLimit = 100
        // Creating query
        pollsToVoteQuery = PFQuery(className: ParsePoll.parseClassName())
        pollsToVoteQuery.includeKey(ParsePollCreatedByKey)
        pollsToVoteQuery.includeKey(ParsePollPhotosKey)
        pollsToVoteQuery.limit = pollsToVoteQueryLimit
        pollsToVoteQuery.orderByDescending(ParseObjectCreatedAtKey)
        // Selecting only relevant polls
        let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
        votesByMeQuery.limit = Int.max
        votesByMeQuery.orderByDescending(ParseObjectCreatedAtKey)
        votesByMeQuery.whereKey(ParseVoteByKey, equalTo: currentUser)
        pollsToVoteQuery.whereKey(ParseObjectIdKey, doesNotMatchKey: ParseVotePollIdKey, inQuery: votesByMeQuery)
        pollsToVoteQuery.whereKey(ParsePollCreatedByKey, notEqualTo: currentUser)
    }

    private func forceUpdate(completionHandler: ((NSError!) -> Void)?) {
        pollsToVoteQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            // Error handling
            if error != nil {
                completionHandler?(error)
                return
            }

            // Add unique objects if poll list is not empty
            if self.polls.count > 0 {
                for pollToAdd in (objects as! [ParsePoll]) {
                    if find(self.polls, pollToAdd) == nil {
                        self.polls.append(pollToAdd)
                    }
                }
                // Order descending
                self.polls.sort({$0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending})
            } else {
                self.polls = objects as! [ParsePoll]
            }

            // Call completion handler
            completionHandler?(error)
        }
    }

    func update(completionHandler: ((NSError!) -> Void)? = nil) {
        let currentUser = ParseUser.currentUser()
        if currentUser.isDirty() {
            currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
                if succeeded {
                    self.forceUpdate(completionHandler)
                } else {
                    completionHandler?(error)
                }
            }
        } else {
            forceUpdate(completionHandler)
        }
    }

    func nextPoll(remove: Bool = true) -> ParsePoll? {

        var nextPoll = polls.first

        while nextPoll?.isValid == false {
            polls.removeAtIndex(0)
            nextPoll = polls.first
        }

        if remove && polls.count > 0 {
            polls.removeAtIndex(0)
        }

        return nextPoll
    }
}

// MARK: - Vote class

let ParseVoteByKey = "voteBy"
let ParseVotePollIdKey = "pollId"
let ParseVoteVoteKey = "vote"

public class ParseVote: PFObject, PFSubclassing {

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

