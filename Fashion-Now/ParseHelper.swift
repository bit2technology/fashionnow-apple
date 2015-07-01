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

let ParseInstallationLanguageKey = "language"
let ParseInstallationLocalizationKey = "localization"
let ParseInstallationLocationKey = "location"
let ParseInstallationPartnersKey = "partners"
let ParseInstallationPushVersionKey = "pushVersion"
let ParseInstallationUserIdKey = "userId"

class ParseInstallation: PFInstallation, PFSubclassing {

    var language: String? {
        get {
            return self[ParseInstallationLanguageKey] as? String
        }
        set {
            self[ParseInstallationLanguageKey] = newValue ?? NSNull()
        }
    }

    var localization: String? {
        get {
            return self[ParseInstallationLocalizationKey] as? String
        }
        set {
            self[ParseInstallationLocalizationKey] = newValue ?? NSNull()
        }
    }

    var location: PFGeoPoint? {
        get {
            return self[ParseInstallationLocationKey] as? PFGeoPoint
        }
        set {
            self[ParseInstallationLocationKey] = newValue ?? NSNull()
        }
    }

    var partners: [String]? {
        get {
            return self[ParseInstallationPartnersKey] as? [String]
        }
        set {
            self[ParseInstallationPartnersKey] = newValue ?? NSNull()
        }
    }

    var pushVersion: Int {
        get {
            return self[ParseInstallationPushVersionKey] as? Int ?? 0
        }
        set {
            self[ParseInstallationPushVersionKey] = newValue ?? NSNull()
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

let ParseUserAdminKey = "admin"
let ParseUserAvatarImageKey = "avatarImage"
let ParseUserBirthdayKey = "birth"
let ParseUserEmailVerifiedKey = "emailVerified"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserHasPasswordKey = "hasPassword"
let ParseUserLocationKey = "location"
let ParseUserNameKey = "name"

private let dateFormat = "yyyy-MM-dd"

class ParseUser: PFUser, PFSubclassing {

    var unsavedPassword = false

    class func current() -> Self {
        return currentUser()!
    }

    var isAdmin: Bool {
        return self[ParseUserAdminKey] as? Bool ?? false
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
                if !(self.email?.fn_count > 0){
                    self.email = user?.email
                }
                if !(self.name?.fn_count > 0) {
                    self.name = user?.first_name
                }
                if !(self.gender?.fn_count > 0) {
                    self.gender = user?.gender
                }
                self.saveInBackgroundWithBlock({ (succeeded, error) -> Void in
                    if error?.domain == PFParseErrorDomain && error?.code == PFErrorCode.ErrorUserEmailTaken.rawValue {
                        self.email = nil
                        self.saveInBackgroundWithBlock(completion)
                    } else {
                        completion?(succeeded, error)
                    }
                })
            }
        } else {
            completion?(true, nil)
        }
    }

    var canPostPoll: Bool {
        if emailVerified {
            return true
        }
        // TODO: What if the user deleted the Facebook account?
        return isLoggedFacebook
    }

    var isLogged: Bool {
        return !PFAnonymousUtils.isLinkedWithUser(self)
    }

    var isLoggedFacebook: Bool {
        return PFFacebookUtils.isLinkedWithUser(self)
    }

    var isValid: Bool {
        if !isLogged {
            return true
        } else if isLoggedFacebook {
            completeInfoFacebook({ (succeeded, error) -> Void in
                FNAnalytics.logError(error, location: "User is valid: Facebook info download")
            })
            return true
        }
        return email?.isEmail() == true && hasPassword == true
    }
}

// MARK: - Friends List class

private let sharedFriendsList = ParseFriendsList()
private let sharedFriendsListPinName = "Friends Cache"

class ParseFriendsList {

    static let FinishLoadingNotification = "ParseFriendsListFinishLoadingNotification"

    /// Shared instance
    class var shared: ParseFriendsList {
        return sharedFriendsList
    }

    private var downloading = false
    private var list = [ParseUser]()

    private var query: PFQuery {
        // Get parse users from Facebook friends
        let friendsQuery = PFQuery(className: ParseUser.parseClassName())
            .orderByAscending(ParseUserNameKey)
        friendsQuery.limit = ParseQueryLimit
        return friendsQuery
    }

    init() {
        query.fromPinWithName(sharedFriendsListPinName).findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
            if !FNAnalytics.logError(error, location: "ParseFriendsList: Local Query") {
                self.list = objects as! [ParseUser]
                self.list.sort({$0.displayName < $1.displayName})
                NSNotificationCenter.defaultCenter().postNotificationName(ParseFriendsList.FinishLoadingNotification, object: self)
            }
            self.update(false)
        })

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
    }

    @objc func loginChanged(sender: NSNotification) {
        PFObject.unpinAllInBackground(list, withName: sharedFriendsListPinName) { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "ParseFriendsList: Unpin (loginChanged)")
            self.list.removeAll(keepCapacity: true)
            self.update(true)
        }
    }

    func update(showError: Bool) {

        // TODO: Show error

        if downloading {
            // Already downloading. Just do nothing.
            return
        }

        downloading = true
        FBSDKGraphRequest(graphPath: "me/friends?fields=id&limit=\(UInt.max)", parameters: nil).startWithCompletionHandler({ (requestConnection, object, error) -> Void in
            self.downloading = false

            if FNAnalytics.logError(error, location: "ParseFriendsList: Facebook Request") {
                NSNotificationCenter.defaultCenter().postNotificationName(ParseFriendsList.FinishLoadingNotification, object: self, userInfo: ["error": error])
                return
            }

            // Get list of IDs from friends
            var friendsFacebookIds = [String]()
            if let friendsFacebook = object["data"] as? [[String:String]] {

                for friendFacebook in friendsFacebook {
                    friendsFacebookIds.append(friendFacebook["id"]!)
                }


                self.query.whereKey(ParseUserFacebookIdKey, containedIn: friendsFacebookIds).findObjectsInBackgroundWithBlock { (objects, error) -> Void in

                    if FNAnalytics.logError(error, location: "ParseFriendsList: Remote Query") {
                        NSNotificationCenter.defaultCenter().postNotificationName(ParseFriendsList.FinishLoadingNotification, object: self, userInfo: ["error": error!])
                        return
                    }

                    PFObject.unpinAllObjectsInBackgroundWithName(sharedFriendsListPinName, block: { (succeeded, error) -> Void in

                        if FNAnalytics.logError(error, location: "ParseFriendsList: Unpin (update)") {
                            NSNotificationCenter.defaultCenter().postNotificationName(ParseFriendsList.FinishLoadingNotification, object: self, userInfo: ["error": error!])
                            return
                        }

                        PFObject.pinAllInBackground(objects, withName: sharedFriendsListPinName, block: { (succeeded, error) -> Void in

                            FNAnalytics.logError(error, location: "ParseFriendsList: Pin")
                            self.list = objects as! [ParseUser]
                            self.list.sort({$0.displayName < $1.displayName})
                            NSNotificationCenter.defaultCenter().postNotificationName(ParseFriendsList.FinishLoadingNotification, object: self)
                        })
                    })
                }
            } else {
                let noDataError = NSError(fn_code: .NoData)
                FNAnalytics.logError(noDataError, location: "ParseFriendsList: Facebook Request")
                NSNotificationCenter.defaultCenter().postNotificationName(ParseFriendsList.FinishLoadingNotification, object: self)
            }
        })
    }

    // MARK: Array simulation

    var count: Int {
        return list.count
    }

    subscript(index: Int) -> ParseUser? {
        return index < list.count ? list[index] : nil
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
// Vote redundancy
let ParsePollVote1CountKey = "vote1Count"
let ParsePollVote2CountKey = "vote2Count"
let ParsePollVoteTotalCountKey = "voteTotalCount"

public class ParsePoll: PFObject, PFSubclassing {

    public class func parseClassName() -> String {
        return "Poll"
    }
    
    convenience init(user: ParseUser) {
        self.init()
        ACL = PFACL(user: user)
        createdBy = user
        version = 2
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

    var version: Int? {
        get {
            return self[ParsePollVersionKey] as? Int
        }
        set {
            self[ParsePollVersionKey] = newValue ?? NSNull()
        }
    }

    // MARK: Vote redundancy

    var vote1Count: Int? {
        return self[ParsePollVote1CountKey] as? Int
    }

    var vote2Count: Int? {
        return self[ParsePollVote2CountKey] as? Int
    }

    var voteTotalCount: Int? {
        return self[ParsePollVoteTotalCountKey] as? Int
    }

    // MARK: Helper methods

    func incrementVoteCount(vote: Int) {
        switch vote {
        case 1:
            incrementKey(ParsePollVote1CountKey)
        case 2:
            incrementKey(ParsePollVote2CountKey)
        default:
            return
        }
        incrementKey(ParsePollVoteTotalCountKey)
    }

    var reported: Bool {
        get {
            return flag == 1
        }
        set {
            flag = newValue ? 1 : 0
            hidden = hidden ? true : newValue
        }
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

private let ParsePollListQueryLimit = 24
private let ParsePollListUpdateLimitTime: NSTimeInterval = -5 // Needs to be negative

class ParsePollList: Printable, DebugPrintable {

    struct Parameters {

        /// Type of poll list
        enum Type {
            /// Polls uploaded by the an user
            case User(ParseUser?)
            /// Public polls from everyone, except the ones voted by the current user
            case Vote
        }

        enum CreatedBy {
            case Friends
            case FriendsOfFriends
            case Anyone
        }

        // Type of list
        var type: Type
        // Type of author if type of poll is Vote.
        var createdBy: CreatedBy

        var location: PFGeoPoint?
        var maxDistance: Double?

        init(type: Type = .Vote, createdBy: CreatedBy = .Anyone) {
            self.type = type
            self.createdBy = createdBy
        }
    }

    let parameters: Parameters

    // If list is currently downloading content
    private(set) var downloading = false
    private var lastUpdate: NSDate?
    /// Minimum time to update again, in seconds
    private var polls = [ParsePoll]()
    private var pollsAreRemote = false
    private var lastUserIds = [String]()

    /// Return new query by type of list
    var query: PFQuery {
        let currentUser = ParseUser.current()
        let pollQuery = PFQuery(className: ParsePoll.parseClassName())
            .whereKey(ParsePollHiddenKey, notEqualTo: true)
            .includeKey(ParsePollPhotosKey)
            .orderByDescending(ParseObjectCreatedAtKey)
        pollQuery.limit = ParsePollListQueryLimit
        switch parameters.type {
        case .User(let user):
            return pollQuery.whereKey(ParsePollCreatedByKey, equalTo: user ?? currentUser)
        case .Vote:
            if currentUser.objectId?.fn_count > 0 {
                // Remove already voted polls
                let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
                    .orderByDescending(ParseVotePollCreatedAtKey)
                    .whereKey(ParseVoteByKey, equalTo: currentUser)
                votesByMeQuery.limit = ParseQueryLimit
                pollQuery.whereKey(ParseObjectIdKey, doesNotMatchKey: ParseVotePollIdKey, inQuery: votesByMeQuery)
                    .whereKey(ParsePollCreatedByKey, notEqualTo: currentUser)
                // Remove blocked users
                let blockedUsersQuery = PFQuery(className: ParseBlock.parseClassName())
                    .orderByDescending(ParseVotePollCreatedAtKey)
                    .whereKey(ParseBlockUserKey, equalTo: currentUser)
                blockedUsersQuery.limit = ParseQueryLimit
                pollQuery.whereKey(ParsePollCreatedByKey, doesNotMatchKey: ParseBlockedKey, inQuery: blockedUsersQuery)
            }
            return pollQuery.includeKey(ParsePollCreatedByKey)
        }
    }

    init(parameters: Parameters = Parameters()) {
        self.parameters = parameters
    }

    /// Type of update request
    enum UpdateType {
        /// Download newer polls
        case Newer
        /// Download older polls
        case Older
    }

    /// Remove next unrepeated poll and return it
    func removeNext() -> ParsePoll? {

        if polls.count <= 0 {
            return nil
        }

        var nextPollIdx: Int?

        // Find
        for (idx, poll) in enumerate(polls) {
            if let userId = poll.createdBy?.objectId where find(lastUserIds, userId) == nil {
                nextPollIdx = idx
                // Add userId to list and remove excess
                lastUserIds.insert(userId, atIndex: 0)
                if lastUserIds.count > 5 {
                    lastUserIds.removeRange(5..<lastUserIds.count)
                }
                break
            }
        }

        // Preload more if necessary
        if polls.count % 10 == 0 || nextPollIdx == nil {
            update(type: .Older, completionHandler: { (succeeded, error) -> Void in
                FNAnalytics.logError(error, location: "Poll List: Preload List")
            })
        }

        // Remove and return
        return polls.removeAtIndex(nextPollIdx ?? 0)
    }

    /// Remove poll by object
    func removePoll(poll: ParsePoll) -> Int? {
        if let index = find(polls, poll) {
            polls.removeAtIndex(index)
            return index
        }
        return nil
    }

    /// Remove poll for given Id and return it
    func remove(#id: String) -> ParsePoll? {

        var pollForIdIdx: Int?

        // Find
        for (idx, poll) in enumerate(polls) {
            if poll.objectId == id {
                pollForIdIdx = idx
                break
            }
        }

        // Remove
        if let idxToRemove = pollForIdIdx {
            return polls.removeAtIndex(idxToRemove)
        }

        return nil
    }

    /// Cache the completion handler from update method and use in the finish method
    private var completionHandler: PFBooleanResultBlock?

    /// Updates (or downloads for the first time) the poll list. It returns true in the completion handler if there is new polls added to the list.
    func update(type: UpdateType = .Newer, completionHandler: PFBooleanResultBlock?) {

        if downloading {

            // Already downloading. Just return error.
            completionHandler?(false, NSError(fn_code: .Busy))
            
        } else if lastUpdate?.timeIntervalSinceNow > ParsePollListUpdateLimitTime {

            // Tried to update too early. Just return error.
            completionHandler?(false, NSError(fn_code: .RequestTooOften))

        } else if Reachability.reachabilityForInternetConnection().isReachable() {

            // Online. Update polls list (or download it for the first time).

            // Configure request
            let pollQuery = query
            if pollsAreRemote {
                switch type {
                case .Newer:
                    if let firstPoll = polls.first {
                        pollQuery.whereKey(ParseObjectCreatedAtKey, greaterThan: firstPoll.createdAt!)
                    }
                case .Older:
                    if let lastPoll = polls.last {
                        pollQuery.whereKey(ParseObjectCreatedAtKey, lessThan: lastPoll.createdAt!)
                    }
                }
            }

            // Start download
            downloading = true
            lastUpdate = NSDate()
            self.completionHandler = completionHandler
            pollQuery.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in

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
            completionHandler?(false, NSError(fn_code: .ConnectionLost))

        } else {

            // Offline. Fill with cached polls if available.

            // Configure request
            let offlineQuery = query.fromLocalDatastore()
            offlineQuery.limit = ParseQueryLimit

            // Start download
            downloading = true
            offlineQuery.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                self.downloading = false

                if let cachedPolls = objects as? [ParsePoll] where cachedPolls.count > 0 {
                    self.polls = cachedPolls
                    completionHandler?(true, error)
                } else {
                    completionHandler?(false, error ?? NSError(fn_code: .NoCache))
                }
            })
        }
    }

    /// Helper method to update
    private func finishDownload(success: Bool, error: NSError!) {
        downloading = false
        completionHandler?(success, error)
        completionHandler = nil
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
        let currentUser = ParseUser.current()
        let vote = ParseVote()
        vote.pollId = poll.objectId
        vote.version = 2
        vote.vote = voteNumber
        vote.voteBy = currentUser
        // Poll redundancy
        vote.pollCreatedAt = poll.createdAt
        vote.pollCreatedById = poll.createdBy?.objectId
        var objectsToSave = [vote] as [PFObject]
        // Vote redundancy in Poll
        if poll.version > 1 {
            poll.incrementVoteCount(voteNumber)
            objectsToSave.append(poll)
        }
        saveAllInBackground(objectsToSave, block: block)
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

    class func sendReport(poll: ParsePoll, comment: String?, block: PFBooleanResultBlock?) {
        let report = self.init()
        let acl = PFACL()
        acl.setPublicReadAccess(true)
        report.ACL = acl
        report.user = ParseUser.current()
        report.pollId = poll.objectId
        report.comment = comment
        var objectsToSave = [report] as [PFObject]
        // Report redundancy in Poll
        if poll.version > 1 {
            poll.reported = true
            objectsToSave.append(poll)
        }
        // Save all
        PFObject.saveAllInBackground(objectsToSave, block: block)
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

// MARK: - Block class

let ParseBlockUserKey = "user"
let ParseBlockedKey = "blocked"

class ParseBlock: PFObject, PFSubclassing {

    class func parseClassName() -> String {
        return "Block"
    }

    class func block(user: ParseUser, block: PFBooleanResultBlock?) {
        let blockObj = self.init()
        let currentUser = ParseUser.current()
        blockObj.ACL = PFACL(user: currentUser)
        blockObj.user = currentUser
        blockObj.blocked = user
        // Save
        blockObj.saveInBackgroundWithBlock(block)
    }

    var blocked: ParseUser? {
        get {
            return self[ParseBlockedKey] as? ParseUser
        }
        set {
            self[ParseBlockedKey] = newValue ?? NSNull()
        }
    }

    var user: ParseUser? {
        get {
            return self[ParseBlockUserKey] as? ParseUser
        }
        set {
            self[ParseBlockUserKey] = newValue ?? NSNull()
        }
    }
}

// MARK: - File

extension PFFile {

    convenience init(fn_imageData data: NSData) {
        self.init(name: "image.jpg", data: data, contentType: "image/jpeg")
    }
}
