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

let ParseQueryLimit = 1000

// MARK: - Installation class

let ParseInstallationLocationKey = "location"
let ParseInstallationUserIdKey = "userId"

public class ParseInstallation: PFInstallation, PFSubclassing {

    var location: PFGeoPoint? {
        get {
            return self[ParseInstallationLocationKey] as? PFGeoPoint
        }
        set {
            self[ParseInstallationLocationKey] = newValue ?? NSNull()
        }
    }

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

//let ParseUserAvatarKey = "avatar"
let ParseUserAvatarImageKey = "avatarImage"
let ParseUserBirthdayKey = "birthday"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserHasPassword = "hasPassword"
let ParseUserLocationKey = "location"
let ParseUserNameKey = "name"

public class ParseUser: PFUser, PFSubclassing {

    override public class func logOut() {
        superclass()?.logOut()
        FBSession.activeSession().closeAndClearTokenInformation()
    }

//    var avatar: ParsePhoto? {
//        get {
//            return self[ParseUserAvatarKey] as? ParsePhoto
//        }
//        set {
//            self[ParseUserAvatarKey] = newValue ?? NSNull()
//        }
//    }

    var avatarImage: PFFile? {
        get {
            return self[ParseUserAvatarImageKey] as? PFFile
        }
        set {
            self[ParseUserAvatarImageKey] = newValue ?? NSNull()
        }
    }

    func avatarURL(size: Int? = nil) -> NSURL? {
        if let unwrappedAvatarPath = avatarImage?.url {
            return NSURL(string: unwrappedAvatarPath)
        } else if let unwrappedFacebookId = facebookId {
            return FacebookHelper.urlForPictureOfUser(id: unwrappedFacebookId, size: size)
        }
        return nil
    }

    var birthday: NSDate? {
        get {
            return self[ParseUserBirthdayKey] as? NSDate
        }
        set {
            self[ParseUserBirthdayKey] = newValue ?? NSNull()
        }
    }

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
let ParsePhotoUserIdKey = "userId"

public class ParsePhoto: PFObject, PFSubclassing {

    public class func parseClassName() -> String {
        return "Photo"
    }

    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL(user: user)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        userId = user.objectId
    }

    var image: PFFile? {
        get {
            return self[ParsePhotoImageKey] as? PFFile
        }
        set {
            self[ParsePhotoImageKey] = newValue ?? NSNull()
        }
    }

    var userId: String? {
        get {
            return self[ParsePhotoUserIdKey] as? String
        }
        set {
            self[ParsePhotoUserIdKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        get {
            return image != nil
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

class ParsePollList: Printable, DebugPrintable {

    enum Type {
        case Mine
        case VotePublic
    }

    private(set) var downloading = false
    private var polls = [ParsePoll]()
    private var pollsAreRemote = false
    let type: Type

    /// Return request handler by type of list
    private var pollQuery: PFQuery {
        let currentUser = ParseUser.currentUser()
        let query = PFQuery(className: ParsePoll.parseClassName())
            .includeKey(ParsePollCreatedByKey)
            .includeKey(ParsePollPhotosKey)
            .orderByDescending(ParseObjectCreatedAtKey)
        query.limit = 1 // FIXME: !!!!
        switch type {
        case .Mine:
            return query.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
        case .VotePublic:
            let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
                .orderByDescending(ParseObjectCreatedAtKey)
                .whereKey(ParseVoteUserIdKey, equalTo: currentUser.objectId)
            votesByMeQuery.limit = ParseQueryLimit
            return query.whereKey(ParseObjectIdKey, doesNotMatchKey: ParseVotePollIdKey, inQuery: votesByMeQuery)
                .whereKey(ParsePollCreatedByKey, notEqualTo: currentUser)
        }
    }

    init(type: Type) {
        self.type = type
    }

    enum UpdateType {
        case Newer
        case Older
    }

    /// Updates (or downloads for the first time) the poll list. It returns true in the completion handler if there is new polls added to the list.
    func update(type: UpdateType = .Newer, completionHandler: PFBooleanResultBlock) {

        if downloading {

            // Already downloading. Just return error.
            completionHandler(false, NSError(domain: AppErrorDomain, code: AppErrorCode.Busy.rawValue, userInfo: nil))
            
        } else if Reachability.reachabilityForInternetConnection().isReachable() {

            // Online. Update polls list (or download is for the first time).

            // Configure request
            let query = pollQuery
            if pollsAreRemote {
                switch type {
                case .Newer:
                    if let unwrappedFirstPoll = polls.first {
                        query.whereKey(ParseObjectCreatedAtKey, greaterThan: unwrappedFirstPoll.createdAt)
                    }
                case .Older:
                    if let unwrappedLastPoll = polls.last {
                        query.whereKey(ParseObjectCreatedAtKey, lessThan: unwrappedLastPoll.createdAt)
                    }
                }
            }

            // Start download
            downloading = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.downloading = false // MARK: !!!!
                var error: NSError?

                let unwrappedNewPolls: [ParsePoll]! = query.findObjects(&error) as? [ParsePoll] // FIXME: Swift 1.2
                if unwrappedNewPolls != nil && unwrappedNewPolls.count > 0 {

                    if self.pollsAreRemote {
                        // Insert before or after depending on type of update
                        switch type {
                        case .Newer:
                            self.polls = unwrappedNewPolls + self.polls
                        case .Older:
                            self.polls += unwrappedNewPolls
                        }

                    } else {
                        // If this is first remote update, replace entire list
                        self.polls = unwrappedNewPolls
                        self.pollsAreRemote = true
                    }

                    PFObject.pinAllInBackground(unwrappedNewPolls, block: nil)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(true, error)
                    })

                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(false, error ?? NSError(domain: AppErrorDomain, code: AppErrorCode.NothingNew.rawValue, userInfo: nil))
                    })
                }
            }

        } else if polls.count > 0 {

            // Offline but polls list is not empty. Just return error.
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(false, NSError(domain: AppErrorDomain, code: AppErrorCode.ConnectionLost.rawValue, userInfo: nil))
            })

        } else {

            // Offline. Fill with cached polls if available.

            // Configure request
            let query = pollQuery.fromLocalDatastore()
            query.limit = ParseQueryLimit

            // Start download
            downloading = true
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                self.downloading = false

                let unwrappedCachedPolls: [ParsePoll]! = objects as? [ParsePoll]
                if unwrappedCachedPolls != nil && unwrappedCachedPolls.count > 0 { // FIXME: Swift 1.2
                    self.polls = unwrappedCachedPolls
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(true, error)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(false, error ?? NSError(domain: AppErrorDomain, code: AppErrorCode.NoCache.rawValue, userInfo: nil))
                    })
                }
            })
        }
    }

    // MARK: Array simulation

    var count: Int {
        return polls.count
    }

    var description: String {
        return polls.description
    }

    var debugDescription: String {
        return polls.debugDescription
    }

    subscript(index: Int) -> ParsePoll? {
        return index < polls.count ? polls[index] : nil
    }
}
















// MARK: DEEEELLLEEEETTTEEEEEEEEEEE

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
        let pollsToVoteQueryLimit = 1000
        // Creating query
        pollsToVoteQuery = PFQuery(className: ParsePoll.parseClassName())
        pollsToVoteQuery.includeKey(ParsePollCreatedByKey)
        pollsToVoteQuery.includeKey(ParsePollPhotosKey)
        pollsToVoteQuery.limit = pollsToVoteQueryLimit
        pollsToVoteQuery.orderByDescending(ParseObjectCreatedAtKey)
        // Selecting only relevant polls
        let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
        votesByMeQuery.limit = pollsToVoteQueryLimit
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
                for pollToAdd in (objects as [ParsePoll]) {
                    if find(self.polls, pollToAdd) == nil {
                        self.polls.append(pollToAdd)
                    }
                }
                // Order descending
                self.polls.sort({$0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending})
            } else {
                self.polls = objects as [ParsePoll]
            }

            // Call completion handler
            completionHandler?(error)
        }
    }

    func update(completionHandler: ((NSError!) -> Void)? = nil) {
        let currentUser = ParseUser.currentUser()
//        if currentUser.isDirty() {
            currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
                if succeeded {
                    self.forceUpdate(completionHandler)
                } else {
                    completionHandler?(error)
                }
            }
//        } else {
//            forceUpdate(completionHandler)
//        }
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
let ParseVoteUserIdKey = "userId"
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

// MARK: - Analytics

//let ParseAnalyticsLoginWithFacebookScreen

extension PFAnalytics {

    class func trackScreenShowInBackground(identifier: String, block: PFBooleanResultBlock!) {
        trackEventInBackground("ScreenShow", dimensions: ["Name": identifier], block: block)
    }
}