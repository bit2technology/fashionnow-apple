//
//  Constants.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-11.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

extension UIColor {

    // MARK: Colors

    class func defaultBlackColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 27/255.0, green: 27/255.0, blue: 27/255.0, alpha: alpha)
    }

    class func defaultDetailColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 7/255.0, green: 131/255.0, blue: 123/255.0, alpha: alpha)
    }

    class func defaultLightColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 10/255.0, green: 206/255.0, blue: 188/255.0, alpha: alpha)
    }

    class func defaultDarkColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 6/255.0, green: 137/255.0, blue: 132/255.0, alpha: alpha)
    }

    class func defaultTintColor(alpha: CGFloat = 1) -> UIColor {
        return defaultDetailColor(alpha: alpha)
    }

    class func defaultDestructiveColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 1, green: 102/255.0, blue: 102/255.0, alpha: alpha)
    }

    class func defaultErrorColor(alpha: CGFloat = 1) -> UIColor {
        return redColor().colorWithAlphaComponent(alpha)
    }

    class func defaultPlaceholderColor(alpha: CGFloat = 1) -> UIColor {
        return lightGrayColor().colorWithAlphaComponent(alpha)
    }

    class func randomColor(alpha: CGFloat = 1) -> UIColor{
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: alpha)
    }

    /// :returns: An image with this color and the specified size
    func image(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {

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

    func compressedJPEGData(maxSize: CGFloat = 1024, compressionQuality: CGFloat = 0.5) -> NSData {

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
            options[kCRToastBackgroundColorKey] = UIColor.defaultErrorColor()
        default:
            break
        }

        CRToastManager.showNotificationWithOptions(options, completionBlock: nil)
    }
}

// MARK: - Mask

func applyPollMask(#left: UIView, right: UIView) {

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
}

/// Returns "OK" for English and its variants for other languages
let LocalizedOKButtonTitle = NSLocalizedString("OK_BUTTON_TITLE", value: "OK" , comment: "Default OK button title for entire app")

/// Returns "OK" for English and its variants for other languages
let LocalizedCancelButtonTitle = NSLocalizedString("CANCEL_BUTTON_TITLE", value: "Cancel" , comment: "Default Cancel button title for entire app")
