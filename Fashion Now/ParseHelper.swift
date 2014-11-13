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

// MARK: - User class

public class User: PFUser, PFSubclassing {

    private let NameKey = "name"
    private let GenderKey = "gender"
    private let BirthdayKey = "birthday"
    private let LocationNameKey = "locationName"

    override public class func load() {
        superclass()?.load()
        registerSubclass()
    }
    
    var name: String? {
        get {
            return self[NameKey] as? String
        }
        set {
            self[NameKey] = newValueOrNSNull(newValue)
        }
    }
    
    var gender: String? {
        get {
            return self[GenderKey] as? String
        }
        set {
            self[GenderKey] = newValueOrNSNull(newValue)
        }
    }

    var birthday: NSDate? {
        get {
            return self[BirthdayKey] as? NSDate
        }
    }
    func setBirthday(#dateString: String?) {
        if let unwrappedDateString = dateString {
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            self[BirthdayKey] = dateFormatter.dateFromString(unwrappedDateString)
            
        } else {
            self[BirthdayKey] = NSNull()
        }
    }
    
    var locationName: String? {
        get {
            return self[LocationNameKey] as? String
        }
        set {
            self[LocationNameKey] = newValueOrNSNull(newValue)
        }
    }
}

// MARK: - Poll class

public class Poll: PFObject, PFSubclassing {

    private let CreatedByKey = "createdBy"
    private let PhotosKey = "photos"
    
    override public class func load() {
        superclass()?.load()
        registerSubclass()
    }

    public class func parseClassName() -> String {
        return "Poll"
    }
    
    override init() {
        super.init()
        createdBy = PFUser.currentUser()
    }

    var createdBy: PFUser? {
        get {
            return self[CreatedByKey] as? PFUser
        }
        set {
            self[CreatedByKey] = newValueOrNSNull(newValue)
        }
    }

    var photos: [Photo]? {
        get {
            return self[PhotosKey] as? [Photo]
        }
        set {
            self[PhotosKey] = newValueOrNSNull(newValue)
        }
    }
}

// MARK: - Photo class

public class Photo: PFObject, PFSubclassing {

    private let UploadedByKey = "uploadedBy"
    private let ImageKey = "image"
    
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

    var uploadedBy: PFUser? {
        get {
            return self[UploadedByKey] as? PFUser
        }
        set {
            self[UploadedByKey] = newValueOrNSNull(newValue)
        }
    }

    var image: PFFile? {
        get {
            return self[ImageKey] as? PFFile
        }
        set {
            self[ImageKey] = newValueOrNSNull(newValue)
        }
    }
}