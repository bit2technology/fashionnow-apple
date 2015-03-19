//
//  Constants.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-11.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

extension UIColor {

    // MARK: Colors

    class func fn_blackColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 27/255.0, green: 27/255.0, blue: 27/255.0, alpha: alpha)
    }

    class func fn_detailColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 7/255.0, green: 131/255.0, blue: 123/255.0, alpha: alpha)
    }

    class func fn_lightColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 10/255.0, green: 206/255.0, blue: 188/255.0, alpha: alpha)
    }

    class func fn_darkColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 6/255.0, green: 137/255.0, blue: 132/255.0, alpha: alpha)
    }

    class func fn_tintColor(alpha: CGFloat = 1) -> UIColor {
        return fn_detailColor(alpha: alpha)
    }

    class func fn_destructiveColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 1, green: 102/255.0, blue: 102/255.0, alpha: alpha)
    }

    class func fn_errorColor(alpha: CGFloat = 1) -> UIColor {
        return redColor().colorWithAlphaComponent(alpha)
    }

    class func fn_placeholderColor(alpha: CGFloat = 1) -> UIColor {
        return lightGrayColor().colorWithAlphaComponent(alpha)
    }

    class func fn_randomColor(alpha: CGFloat = 1) -> UIColor{
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: alpha)
    }

    /// :returns: An image with this color and the specified size
    func fn_image(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {

        UIGraphicsBeginImageContext(size);
        let context = UIGraphicsGetCurrentContext();

        CGContextSetFillColorWithColor(context, CGColor);
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: size));

        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
}

extension UIImage {

    func fn_compressedJPEGData(maxSize: CGFloat = 1024, compressionQuality: CGFloat = 0.5) -> NSData {

        let resizeScale = maxSize / max(size.width, size.height)

        var img: UIImage?
        if resizeScale < 1 {
            let resizeRect = CGRect(x: 0, y: 0, width: size.width * resizeScale, height: size.height * resizeScale)
            UIGraphicsBeginImageContext(resizeRect.size)
            drawInRect(resizeRect)
            img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }

        return UIImageJPEGRepresentation(img ?? self, compressionQuality)
    }
}

/// UIButton that gets the background image and apply template rendering mode
class TemplateBackgroundButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()

        setBackgroundImage(backgroundImageForState(.Normal), forState: .Normal)
    }

    override func setBackgroundImage(image: UIImage?, forState state: UIControlState) {
        super.setBackgroundImage(image?.imageWithRenderingMode(.AlwaysTemplate), forState: state)
    }
}

/// Helper for CRToastManager
class Toast {

    enum Type {
        case Default, Error
    }

    class func show(#text: String, type: Type = .Default) {

        var options = [String: AnyObject]()

        // Text
        options[kCRToastTextKey] = text

        // Background Color
        switch type {
        case .Error:
            options[kCRToastBackgroundColorKey] = UIColor.fn_errorColor()
        default:
            break
        }

        CRToastManager.showNotificationWithOptions(options, completionBlock: nil)
    }
}

// MARK: - Mask

func fn_applyPollMask(left: UIView, right: UIView) {

    let maskReferenceSize: CGFloat = 1
    let spaceBetween: CGFloat = maskReferenceSize / 100

    let leftMaskPath = UIBezierPath()
    leftMaskPath.moveToPoint(CGPoint(x: -6 * maskReferenceSize, y: 0))
    leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize + (maskReferenceSize / 10) - spaceBetween, y: 0))
    leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize - (maskReferenceSize / 10) - spaceBetween, y: maskReferenceSize))
    leftMaskPath.addLineToPoint(CGPoint(x: -6 * maskReferenceSize, y: maskReferenceSize))
    leftMaskPath.closePath()
    let leftMask = CAShapeLayer()
    leftMask.path = leftMaskPath.CGPath
    left.layer.mask = leftMask

    let rightMaskPath = UIBezierPath()
    rightMaskPath.moveToPoint(CGPoint(x: 7 * maskReferenceSize, y: 0))
    rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / 10) + spaceBetween, y: 0))
    rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / -10) + spaceBetween, y: maskReferenceSize))
    rightMaskPath.addLineToPoint(CGPoint(x: 7 * maskReferenceSize, y: maskReferenceSize))
    rightMaskPath.closePath()
    let rightMask = CAShapeLayer()
    rightMask.path = rightMaskPath.CGPath
    right.layer.mask = rightMask
}

extension String {
    var fn_count: Int {
        return countElements(self)
    }
}

extension NSDate {
    /// Show description for date
    var fn_birthdayDescription: String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "GMT")
        dateFormatter.dateStyle = .MediumStyle
        return dateFormatter.stringFromDate(self)
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}

// MARK: - Constants

/// Notification name for new poll saved
let NewPollSavedNotificationName = "NewPollSavedNotification"
/// Notification name for poll deleted
let PollDeletedNotificationName = "PollDeletedNotification"

/// Default error domain
let AppErrorDomain = "com.bit2software.Fashion-Now"

/// Error codes
enum AppErrorCode: Int {
    /// The operator is busy, probably from network activity
    case Busy = 800
    /// App tried update, but there's nothing new
    case NothingNew = 801
    /// App was online, but now is offline
    case ConnectionLost = 802
    /// App is offline and has no cache content
    case NoCache = 803
    /// Requests are limited. We need to save them.
    case RequestTooOften = 804
}

let fn_localizedOfflineErrorDescription = NSLocalizedString("OFFLINE_ERROR_DESCRIPTION", value: "You are offline. Try again later." , comment: "Default for entire app")

/// Returns "OK" for English and its variants for other languages
let LocalizedOKButtonTitle = NSLocalizedString("OK_BUTTON_TITLE", value: "OK" , comment: "Default OK button title for entire app")

/// Returns "Cancel" for English and its variants for other languages
let LocalizedCancelButtonTitle = NSLocalizedString("CANCEL_BUTTON_TITLE", value: "Cancel" , comment: "Default Cancel button title for entire app")
