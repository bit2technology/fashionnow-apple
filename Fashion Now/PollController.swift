//
//  PhotoComparisonController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit
import QuartzCore

internal class PollController: UIViewController {
    
    var poll: Poll = Poll() {
        didSet {
            if let unwrappedPhotos = poll.photos {
                leftPhotoController.photo = unwrappedPhotos[0]
                rightPhotoController.photo = unwrappedPhotos[1]
            }
        }
    }
    
    private(set) var leftPhotoController: PhotoController!
    private(set) var rightPhotoController: PhotoController!

    @IBOutlet var leftPhotoView: UIView!
    @IBOutlet var rightPhotoView: UIView!

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let identifier = segue.identifier {

            switch identifier {

            case "Left Photo Controller":
                leftPhotoController = segue.destinationViewController as PhotoController

            case "Right Photo Controller":
                rightPhotoController = segue.destinationViewController as PhotoController

            default:
                return
            }
        }
    }
}
