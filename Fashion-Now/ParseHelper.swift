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

class ParseInstallation: PFInstallation, PFSubclassing {

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

let ParseUserAvatarImageKey = "avatarImage"
let ParseUserBirthdayKey = "birthday"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserHasPassword = "hasPassword"
let ParseUserLocationKey = "location"
let ParseUserNameKey = "name"

class ParseUser: PFUser, PFSubclassing {

    override class func logOut() {
        superclass()?.logOut()
        FBSession.activeSession().closeAndClearTokenInformation()
    }

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

    var birthday: NSDate! {
        get {
            let timeZoneIndependentFormatter = NSDateFormatter()
            timeZoneIndependentFormatter.timeZone = NSTimeZone(name: "GMT")
            timeZoneIndependentFormatter.dateFormat = "yyyy-MM-dd"
            let adjustedNewBirthdayString = timeZoneIndependentFormatter.stringFromDate(birthdayNative ?? NSDate())
            timeZoneIndependentFormatter.timeZone = nil
            return timeZoneIndependentFormatter.dateFromString(adjustedNewBirthdayString)
        }
        set {
            if newValue != nil {
                let timeZoneIndependentFormatter = NSDateFormatter()
                timeZoneIndependentFormatter.dateFormat = "yyyy-MM-dd"
                let adjustedNewBirthdayString = timeZoneIndependentFormatter.stringFromDate(birthdayNative!)
                timeZoneIndependentFormatter.timeZone = NSTimeZone(name: "GMT")
                birthdayNative = timeZoneIndependentFormatter.dateFromString(adjustedNewBirthdayString)
            } else {
                birthdayNative = nil
            }
        }
    }

    private var birthdayNative: NSDate? {
        get {
            return self[ParseUserBirthdayKey] as? NSDate
        }
        set {
            self[ParseUserBirthdayKey] = newValue ?? NSNull()
        }
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

    // MARK: Helper methods

    var isValid: Bool {
        return PFAnonymousUtils.isLinkedWithUser(self) || (self.hasPassword == true && self.email?.isEmail() == true)
    }
}

// MARK: - Photo class

let ParsePhotoImageKey = "image"
let ParsePhotoUserIdKey = "userId"

class ParsePhoto: PFObject, PFSubclassing {

    class func parseClassName() -> String {
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
        return image != nil // Don't verify userId for compatibility reason and irrelevance
    }
}

// MARK: - Poll class

let ParsePollCaptionKey = "caption"
let ParsePollCreatedByKey = "createdBy"
let ParsePollPhotosKey = "photos"
let ParsePollUserIdsKey = "userIds"
let ParsePollVersionKey = "version"

public class ParsePoll: PFObject, PFSubclassing {

    public class func parseClassName() -> String {
        return "Poll"
    }
    
    convenience init(user: ParseUser) {
        self.init()
        ACL = PFACL(user: user)
        createdBy = user
        version = 1
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

    var userIds: [String]? {
        get {
            return self[ParsePollUserIdsKey] as? [String]
        }
        set {
            self[ParsePollUserIdsKey] = newValue ?? NSNull()
        }
    }

    var version: NSNumber? {
        get {
            return self[ParsePollVersionKey] as? NSNumber
        }
        set {
            self[ParsePollVersionKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
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

class ParsePollList: Printable, DebugPrintable {

    // It there is more than one type of not vote, algorithm must change
    /// Type of poll list
    enum Type {
        /// Polls uploaded by the current user
        case Mine
        /// Public polls from everyone, except the ones voted by the current user
        case VotePublic
    }

    // If list is currently downloading content
    private(set) var downloading = false
    private var lastUpdate: NSDate?
    /// Minimum time to update again, in seconds
    private let updateLimitTime: NSTimeInterval = -5 // Needs to be negative
    private var polls = [ParsePoll]()
    private var pollsAreRemote = false
    // Type of list
    let type: Type

    /// Return new query by type of list
    private var pollQuery: PFQuery {
        let currentUser = ParseUser.currentUser()
        let query = PFQuery(className: ParsePoll.parseClassName())
            .includeKey(ParsePollCreatedByKey)
            .includeKey(ParsePollPhotosKey)
            .orderByDescending(ParseObjectCreatedAtKey)
        switch type {
        case .Mine:
            return query.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
        case .VotePublic:
            if !PFAnonymousUtils.isLinkedWithUser(currentUser) {
                let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
                    .orderByDescending(ParseObjectCreatedAtKey)
                    .whereKey(ParseVoteByKey, equalTo: currentUser)
                votesByMeQuery.limit = ParseQueryLimit
                query.whereKey(ParseObjectIdKey, doesNotMatchKey: ParseVotePollIdKey, inQuery: votesByMeQuery)
            }
            return query.whereKey(ParsePollCreatedByKey, notEqualTo: currentUser)
        }
    }

    init(type: Type) {
        self.type = type
    }

    /// Type of update request
    enum UpdateType {
        /// Download newer polls
        case Newer
        /// Download older polls
        case Older
    }

    /// Return next poll (generally to vote) and optionally, remove it from the list
    func nextPoll(#remove: Bool) -> ParsePoll? {

        if polls.count > 0 {
            let nextPoll = polls[0]
            if remove {
                polls.removeAtIndex(0)
            }
            return nextPoll
        }
        return nil
    }

    /// Cache the completion handler from update method and use in the finish method
    private var completionHandler: PFBooleanResultBlock?

    /// Updates (or downloads for the first time) the poll list. It returns true in the completion handler if there is new polls added to the list.
    func update(type: UpdateType = .Newer, completionHandler: PFBooleanResultBlock) {

        if downloading {

            // Already downloading. Just return error.
            completionHandler(false, NSError(domain: FNErrorDomain, code: FNErrorCode.Busy.rawValue, userInfo: nil))
            
        } else if lastUpdate?.timeIntervalSinceNow > updateLimitTime {

            // Tried to update too early. Just return error.
            completionHandler(false, NSError(domain: FNErrorDomain, code: FNErrorCode.RequestTooOften.rawValue, userInfo: nil))

        } else if Reachability.reachabilityForInternetConnection().isReachable() {

            // Online. Update polls list (or download it for the first time).

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
            self.completionHandler = completionHandler
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                var error: NSError?

                // Save user if needed
                let currentUser = ParseUser.currentUser()
                if currentUser.isDirty() {
                    currentUser.save(&error)
                    if error != nil {
                        self.finish(false, error: error)
                        return
                    }
                }

                var unwrappedNewPolls: [ParsePoll]! = query.findObjects(&error) as? [ParsePoll] // FIXME: Swift 1.2
                if error == nil && unwrappedNewPolls != nil && unwrappedNewPolls.count > 0 {

                    // Remove already voted polls only if type is one of the vote types
                    if self.type != .Mine {

                        // Collect new polls IDs
                        var newPollsIds = [String]()
                        for poll in unwrappedNewPolls {
                            newPollsIds.append(poll.objectId)
                        }

                        // Find votes on these new polls
                        let myVotesQuery = PFQuery(className: ParseVote.parseClassName())
                            .whereKey(ParseVotePollIdKey, containedIn: newPollsIds)
                            .whereKey(ParseVoteByKey, equalTo: currentUser)
                        myVotesQuery.limit = ParseQueryLimit
                        let myVotes = myVotesQuery.findObjects(&error) as? [ParseVote]
                        if error != nil {
                            self.finish(false, error: error)
                            return
                        }
                        if myVotes?.count >= unwrappedNewPolls.count {
                            // All new polls are voted. Just return error.
                            self.finish(false, error: NSError(domain: FNErrorDomain, code: FNErrorCode.NothingNew.rawValue, userInfo: nil))
                            return
                        }
                        if myVotes?.count > 0 {
                            // Collect already voted polls IDs
                            var myVotesPollIds = [String]()
                            for vote in myVotes! {
                                myVotesPollIds.append(vote.pollId!)
                            }
                            // Remove the ones already voted
                            var notVotedNewPolls = [ParsePoll]()
                            for newPoll in unwrappedNewPolls {
                                if find(myVotesPollIds, newPoll.objectId) == nil {
                                    notVotedNewPolls.append(newPoll)
                                }
                            }
                            unwrappedNewPolls = notVotedNewPolls
                        }
                    }

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

                    // Cache polls and return
                    PFObject.pinAllInBackground(unwrappedNewPolls, block: nil)
                    self.finish(true, error: error)

                } else {

                    // Download error or no more polls
                    self.finish(false, error: error ?? NSError(domain: FNErrorDomain, code: FNErrorCode.NothingNew.rawValue, userInfo: nil))
                }
            }

        } else if polls.count > 0 {

            // Offline but polls list is not empty. Just return error.
            completionHandler(false, NSError(domain: FNErrorDomain, code: FNErrorCode.ConnectionLost.rawValue, userInfo: nil))

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
                    completionHandler(true, error)
                } else {
                    completionHandler(false, error ?? NSError(domain: FNErrorDomain, code: FNErrorCode.NoCache.rawValue, userInfo: nil))
                }
            })
        }
    }

    /// Helper method to update
    private func finish(success: Bool, error: NSError!) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.downloading = false
            self.lastUpdate = NSDate()
            self.completionHandler?(success, error)
            self.completionHandler = nil
        })
    }

    /// Remove poll by object
    func removePoll(poll: ParsePoll) -> Bool {
        if let index = find(polls, poll) {
            polls.removeAtIndex(index)
            return true
        }
        return false
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

// MARK: - Vote class

let ParseVoteByKey = "voteBy"
let ParseVotePollIdKey = "pollId"
let ParseVoteVoteKey = "vote"

class ParseVote: PFObject, PFSubclassing {

    class func parseClassName() -> String {
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
        return pollId?.fn_count > 0 && vote != nil && voteBy != nil
    }
}

// MARK: - Analytics

extension PFAnalytics {

    class func fn_trackScreenShowInBackground(identifier: String, block: PFBooleanResultBlock! = nil) {
        trackEventInBackground("ScreenShow", dimensions: ["Name": identifier], block: block)
    }
}