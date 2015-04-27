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

// MARK: - Config extension

extension PFConfig {
    var pollDateLimit: NSTimeInterval? {
        return self["pollDateLimit"] as? NSTimeInterval
    }
}

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
let ParseUserBirthdayKey = "birth"
let ParseUserEmailVerifiedKey = "emailVerified"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserHasPasswordKey = "hasPassword"
let ParseUserHasUsernameKey = "hasUsername"
let ParseUserLocationKey = "location"
let ParseUserNameKey = "name"

private let dateFormat = "yyyy-MM-dd"

class ParseUser: PFUser, PFSubclassing {

    class func current() -> Self {
        return currentUser()!
    }

    var avatarImage: PFFile? {
        get {
            return self[ParseUserAvatarImageKey] as? PFFile
        }
        set {
            self[ParseUserAvatarImageKey] = newValue ?? NSNull()
        }
    }

    /// Returns the url for the avatar (in parse, facebook or none)
    func avatarURL(size: CGFloat? = nil) -> NSURL? {
        if let avatarURL = avatarImage?.url {
            return NSURL(string: avatarURL)
        } else if let facebookId = facebookId {
            return FacebookUser(id: facebookId).avatarUrl(size: size)
        }
        return nil
    }

    /// Converts date string in NSDate and vice-versa
    var birthday: NSDate? {
        get {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = dateFormat
            return dateFormatter.dateFromString(self[ParseUserBirthdayKey] as? String ?? "")
        }
        set {
            if let date = newValue {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = dateFormat
                self[ParseUserBirthdayKey] = dateFormatter.stringFromDate(date)
            } else {
                self[ParseUserBirthdayKey] = NSNull()
            }

        }
    }

    var displayName: String {
        return name ?? username!
    }

    var emailVerified: Bool {
        return self[ParseUserEmailVerifiedKey] as? Bool ?? false
    }

    var facebookId: String? {
        return self[ParseUserFacebookIdKey] as? String
    }

    var gender: String? {
        get {
            return self[ParseUserGenderKey] as? String
        }
        set {
            self[ParseUserGenderKey] = newValue ?? NSNull()
        }
    }

    var hasPassword: Bool {
        get {
            return self[ParseUserHasPasswordKey] as? Bool ?? false
        }
        set {
            self[ParseUserHasPasswordKey] = newValue
        }
    }

    var hasUsername: Bool {
        get {
            return self[ParseUserHasUsernameKey] as? Bool ?? false
        }
        set {
            self[ParseUserHasUsernameKey] = newValue
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

    /// This method downloads info from logged Facebook account and completes the user object if necessary.
    func completeInfoFacebook(completion: PFBooleanResultBlock?) {
        if !(facebookId?.fn_count > 0) {
            FacebookUser.getCurrent { (user, error) -> Void in
                if !(self.name?.fn_count > 0) {
                    self.name = user?.first_name
                }
                if !(self.email?.fn_count > 0) {
                    self.email = user?.email
                }
                if !(self.gender?.fn_count > 0) {
                    self.gender = user?.gender
                }
                self.saveInBackgroundWithBlock(completion)
            }
        }
    }

    var canPostPoll: Bool {
        if emailVerified {
            return true
        }
        // TODO: Verify other ways
        return false
    }

    var isLogged: Bool {
        return !PFAnonymousUtils.isLinkedWithUser(self)
    }

    var isLoggedFacebook: Bool {
        return PFFacebookUtils.isLinkedWithUser(self)
    }

    var isValid: Bool {
        if PFAnonymousUtils.isLinkedWithUser(self) {
            return true
        } else if PFFacebookUtils.isLinkedWithUser(self) {
            completeInfoFacebook({ (succeeded, error) -> Void in
                FNAnalytics.logError(error, location: "User is valid: Facebook info download")
            })
            return true
        }
        return email?.isEmail() == true && hasUsername == true && hasPassword == true
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
        return image != nil
    }
}

// MARK: - Poll class

let ParsePollCaptionKey = "caption"
let ParsePollCreatedByKey = "createdBy"
let ParsePollFlagKey = "flag"
let ParsePollHiddenKey = "hidden"
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

    var flag: Int {
        get {
            return self[ParsePollFlagKey] as? Int ?? 0
        }
        set {
            self[ParsePollFlagKey] = newValue
        }
    }

    var hidden: Bool {
        get {
            return self[ParsePollHiddenKey] as? Bool ?? false
        }
        set {
            self[ParsePollHiddenKey] = newValue
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

    var version: Int? {
        get {
            return self[ParsePollVersionKey] as? Int
        }
        set {
            self[ParsePollVersionKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    func incrementVoteCount(vote: Int?) {
        // TODO: !!!!!!!!
    }

    var isValid: Bool {
        if photos == nil {
            return false
        }
        for photo in photos! {
            if !photo.isValid {
                return false
            }
        }
        return createdBy != nil
    }
}

// MARK: - Poll List class

private let pollLimit = 24
private let updateLimitTime: NSTimeInterval = -5 // Needs to be negative

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
    private var polls = [ParsePoll]()
    private var pollsAreRemote = false
    // Type of list
    let type: Type

    /// Return new query by type of list
    private var pollQuery: PFQuery {
        let currentUser = ParseUser.current()
        let query = PFQuery(className: ParsePoll.parseClassName())
            .includeKey(ParsePollCreatedByKey)
            .includeKey(ParsePollPhotosKey)
            .orderByDescending(ParseObjectCreatedAtKey)
        query.limit = pollLimit
        switch type {
        case .Mine:
            return query.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
        case .VotePublic:
            if currentUser.objectId?.fn_count > 0 {
                let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
                    .orderByDescending(ParseObjectCreatedAtKey)
                    .whereKey(ParseVoteByKey, equalTo: currentUser)
                votesByMeQuery.limit = ParseQueryLimit
                query.whereKey(ParseObjectIdKey, doesNotMatchKey: ParseVotePollIdKey, inQuery: votesByMeQuery)
                    .whereKey(ParsePollCreatedByKey, notEqualTo: currentUser)
            }
            return query
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
            completionHandler(false, NSError(fn_code: .Busy))
            
        } else if lastUpdate?.timeIntervalSinceNow > updateLimitTime {

            // Tried to update too early. Just return error.
            completionHandler(false, NSError(fn_code: .RequestTooOften))

        } else if Reachability.reachabilityForInternetConnection().isReachable() {

            // Online. Update polls list (or download it for the first time).

            // Configure request
            let query = pollQuery
            if pollsAreRemote {
                switch type {
                case .Newer:
                    if let firstPoll = polls.first {
                        query.whereKey(ParseObjectCreatedAtKey, greaterThan: firstPoll.createdAt!)
                    }
                case .Older:
                    if let lastPoll = polls.last {
                        query.whereKey(ParseObjectCreatedAtKey, lessThan: lastPoll.createdAt!)
                    }
                }
            }

            // Start download
            downloading = true
            self.completionHandler = completionHandler
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in

                if let newPolls = objects as? [ParsePoll] where newPolls.count > 0 {

                    if self.pollsAreRemote {
                        // Insert before or after depending on type of update
                        switch type {
                        case .Newer:
                            self.polls = newPolls + self.polls
                        case .Older:
                            self.polls += newPolls
                        }

                    } else {
                        // If this is first remote update, replace entire list
                        self.polls = newPolls
                        self.pollsAreRemote = true
                    }

                    // Cache polls and return
                    PFObject.pinAllInBackground(newPolls, block: nil)
                    self.finishDownload(true, error: error)

                } else {

                    // Download error or no more polls
                    self.finishDownload(false, error: error ?? NSError(fn_code: .NothingNew))
                }
            })

        } else if polls.count > 0 {

            // Offline but polls list is not empty. Just return error.
            completionHandler(false, NSError(fn_code: .ConnectionLost))

        } else {

            // Offline. Fill with cached polls if available.

            // Configure request
            let query = pollQuery.fromLocalDatastore()
            query.limit = ParseQueryLimit

            // Start download
            downloading = true
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                self.downloading = false

                if let cachedPolls = objects as? [ParsePoll] where cachedPolls.count > 0 {
                    self.polls = cachedPolls
                    completionHandler(true, error)
                } else {
                    completionHandler(false, error ?? NSError(fn_code: .NoCache))
                }
            })
        }
    }

    /// Helper method to update
    private func finishDownload(success: Bool, error: NSError!) {
        downloading = false
        lastUpdate = NSDate()
        completionHandler?(success, error)
        completionHandler = nil
    }

    /// Remove poll by object
    func removePoll(poll: ParsePoll) -> Int? {
        if let index = find(polls, poll) {
            polls.removeAtIndex(index)
            return index
        }
        return nil
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
let ParseVotePollCreatedAtKey = "pollCreatedAt"
let ParseVotePollCreatedByIdKey = "pollCreatedBy"
let ParseVoteVersionKey = "version"
let ParseVoteVoteKey = "vote"

class ParseVote: PFObject, PFSubclassing {

    class func parseClassName() -> String {
        return "Vote"
    }

    class func sendVote(vote voteNumber: Int, poll: ParsePoll, block: PFBooleanResultBlock?) {
        let vote = ParseVote()
        vote.pollId = poll.objectId
        vote.version = 2
        vote.vote = voteNumber
        // Poll redundancy
        vote.pollCreatedAt = poll.createdAt
        vote.pollCreatedById = poll.createdBy?.objectId
        // Vote redundancy in Poll
        poll.incrementVoteCount(voteNumber)
        saveAllInBackground([vote, poll], block: block)
    }

    var pollId: String? {
        get {
            return self[ParseVotePollIdKey] as? String
        }
        set {
            self[ParseVotePollIdKey] = newValue ?? NSNull()
        }
    }

    var pollCreatedAt: NSDate? {
        get {
            return self[ParseVotePollCreatedAtKey] as? NSDate
        }
        set {
            self[ParseVotePollCreatedAtKey] = newValue ?? NSNull()
        }
    }

    var pollCreatedById: String? {
        get {
            return self[ParseVotePollCreatedByIdKey] as? String
        }
        set {
            self[ParseVotePollCreatedByIdKey] = newValue ?? NSNull()
        }
    }

    var vote: Int? {
        get {
            return self[ParseVoteVoteKey] as? Int
        }
        set {
            self[ParseVoteVoteKey] = newValue ?? NSNull()
        }
    }

    var version: Int? {
        get {
            return self[ParseVoteVersionKey] as? Int
        }
        set {
            self[ParseVoteVersionKey] = newValue ?? NSNull()
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

// MARK: - Report class

let ParseReportCommentKey = "comment"
let ParseReportPollIdKey = "pollId"
let ParseReportUserKey = "user"

class ParseReport: PFObject, PFSubclassing {

    class func parseClassName() -> String {
        return "Report"
    }

    convenience init(user: ParseUser) {
        self.init()
        ACL = PFACL(user: user)
        self.user = user
    }

    var comment: String? {
        get {
            return self[ParseReportCommentKey] as? String
        }
        set {
            self[ParseReportCommentKey] = newValue ?? NSNull()
        }
    }

    var pollId: String? {
        get {
            return self[ParseReportPollIdKey] as? String
        }
        set {
            self[ParseReportPollIdKey] = newValue ?? NSNull()
        }
    }

    var user: ParseUser? {
        get {
            return self[ParseReportUserKey] as? ParseUser
        }
        set {
            self[ParseReportUserKey] = newValue ?? NSNull()
        }
    }
}

// MARK: - File

extension PFFile {

    convenience init(fn_imageData data: NSData) {
        self.init(name: "image.jpg", data: data, contentType: "image/jpeg")
    }
}
