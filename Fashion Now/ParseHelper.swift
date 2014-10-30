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

    var isValid: Bool {
        get {
            return (createdBy != nil && photos?.count >= 2)
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