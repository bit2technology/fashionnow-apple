//
//  Constants.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-11.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

// MARK: - Extensions

extension UIColor {

    /// rgb(27, 27, 27)
    class func fn_black(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 0.10588235294117647058823529411764705882352941176471, green: 0.10588235294117647058823529411764705882352941176471, blue: 0.10588235294117647058823529411764705882352941176471, alpha: alpha)
    }

    /// rgb(255, 255, 255)
    class func fn_white(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 1, green: 1, blue: 1, alpha: alpha)
    }

    /// rgb(7, 131, 123)
    class func fn_detail(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 0.027450980392156862745098039215686274509803921568627, green: 0.51372549019607843137254901960784313725490196078431, blue: 0.48235294117647058823529411764705882352941176470588, alpha: alpha)
    }

    /// rgb(10, 206, 188)
    class func fn_light(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 0.039215686274509803921568627450980392156862745098039, green: 0.80784313725490196078431372549019607843137254901961, blue: 0.73725490196078431372549019607843137254901960784314, alpha: alpha)
    }

    /// rgb(6, 137, 132)
    class func fn_dark(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 0.023529411764705882352941176470588235294117647058824, green: 0.53725490196078431372549019607843137254901960784314, blue: 0.51764705882352941176470588235294117647058823529412, alpha: alpha)
    }

    /// rgb(7, 131, 123)
    class func fn_tint(alpha: CGFloat = 1) -> UIColor {
        return fn_detail(alpha: alpha)
    }

    /// rgb(255, 0, 0)
    class func fn_error(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 1, green: 0, blue: 0, alpha: alpha)
    }

    /// rgb(211, 211, 211)
    class func fn_placeholder(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 0.82745098039215686274509803921568627450980392156863, green: 0.82745098039215686274509803921568627450980392156863, blue: 0.82745098039215686274509803921568627450980392156863, alpha: alpha)
    }

    /// :returns: Random color
    class func fn_random(alpha: CGFloat = 1) -> UIColor{
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

    /// :returns: Compressed JPEG Data, opaque and with scale 1
    func fn_compressed(maxSize: CGFloat = 1024, compressionQuality: CGFloat = 0.5) -> NSData {

        let resizeScale = maxSize / max(size.width, size.height)

        var img: UIImage?
        if resizeScale < 1 {
            let resizeRect = CGRect(x: 0, y: 0, width: floor(size.width * resizeScale), height: floor(size.height * resizeScale))
            UIGraphicsBeginImageContextWithOptions(resizeRect.size, true, 1)
            drawInRect(resizeRect)
            img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return UIImageJPEGRepresentation(img ?? self, compressionQuality)
    }

    /// :returns: Resized image if necessary, opaque and with screen scale
    func fn_resized(maxHeight: CGFloat) -> UIImage {

        let resizeScale = maxHeight / self.size.height

        if resizeScale < 1 {
            let resizeRect = CGRect(x: 0, y: 0, width: floor(size.width * resizeScale), height: floor(size.height * resizeScale))
            UIGraphicsBeginImageContextWithOptions(resizeRect.size, true, UIScreen.mainScreen().scale)
            drawInRect(resizeRect)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img
        }
        return self
    }
}

extension String {
    /// Same as count(self)
    var fn_count: Int {
        return countElements(self)
    }
}

extension NSDate {
    /// Show description for date
    var fn_birthdayDescription: String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        return dateFormatter.stringFromDate(self)
    }
}

// MARK: Interface Builder Inspectables

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
    @IBInspectable var shouldRasterize: Bool {
        get {
            return layer.shouldRasterize
        }
        set {
            layer.shouldRasterize = newValue
        }
    }

    /// Set an activity indicator view as subview, covering everything and returns it.
    func fn_setLoading(small: Bool = false, transluscent: Bool = false) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: small ? .White : .WhiteLarge)
        activityIndicator.color = UIColor.grayColor()
        activityIndicator.backgroundColor = UIColor.fn_white(alpha: transluscent ? 0.5 : 1)
        activityIndicator.startAnimating()
        activityIndicator.frame = self.bounds
        activityIndicator.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        activityIndicator.opaque = true
        self.addSubview(activityIndicator)
        return activityIndicator
    }
}

extension UIImageView {
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }

    /// Adjusts the image view aspect ratio constraint to the size of the image
    func fn_setAspectRatio(image: UIImage?, needsLayout: Bool = true) {

        if let correctImage = image ?? self.image {
            // Remove old aspect ratio
            if NSLayoutConstraint.respondsToSelector("deactivateConstraints:") {
                NSLayoutConstraint.deactivateConstraints(self.constraints())
            } else {
                self.removeConstraints(self.constraints())
            }

            // Add new
            self.addConstraint(NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: correctImage.size.width / correctImage.size.height, constant: 0))
            if needsLayout {
                self.setNeedsLayout()
            }
        }
    }
}

// MARK: - Classes

/// UIButton that gets the background image and apply template rendering mode
class FNTemplateBackgroundButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()

        setBackgroundImage(backgroundImageForState(.Normal), forState: .Normal)
    }

    override func setBackgroundImage(image: UIImage?, forState state: UIControlState) {
        super.setBackgroundImage(image?.imageWithRenderingMode(.AlwaysTemplate), forState: state)
    }
}

/// Helper for CRToastManager
class FNToast {

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
            options[kCRToastBackgroundColorKey] = UIColor.fn_error()
        default:
            break
        }

        CRToastManager.showNotificationWithOptions(options, completionBlock: nil)
    }
}

// MARK: - Mask

/// Apply tilted separator
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

// MARK: - Constants

/// Notification name for new poll saved
let FNPollPostedNotificationName = "PollPostedNotification"
/// Notification name for poll deleted
let FNPollDeletedNotificationName = "PollDeletedNotification"

/// Default error domain
let FNErrorDomain = "com.bit2software.Fashion-Now"

/// Error codes
enum FNErrorCode: Int {
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
    /// Tried to load a Photo with no image URL.
    case NoPhotoURL = 805
}

let FNLocalizedAppName = NSLocalizedString("APP_NAME", value: "Fashion Now" , comment: "Default for entire app")

/// Returns "You are offline. Try again later." for English and its variants for other languages
let FNLocalizedOfflineErrorDescription = NSLocalizedString("DEFAULT_ERROR_DESCRIPTION_OFFLINE", value: "You are offline. Try again later." , comment: "Default for entire app")

/// Returns "OK" for English and its variants for other languages
let FNLocalizedOKButtonTitle = NSLocalizedString("DEFAULT_BUTTON_TITLE_OK", value: "OK" , comment: "Default OK button title for entire app")

/// Returns "Cancel" for English and its variants for other languages
let FNLocalizedCancelButtonTitle = NSLocalizedString("DEFAULT_BUTTON_TITLE_CANCEL", value: "Cancel" , comment: "Default Cancel button title for entire app")
