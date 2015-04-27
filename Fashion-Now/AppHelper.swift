//
//  Constants.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-11.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

// MARK: - Functions

/// Apply tilted separator
func fn_applyPollMask(left: UIView, right: UIView) {

    let maskReferenceSize: CGFloat = 1
    let spaceBetween: CGFloat = maskReferenceSize / 100

    let leftMaskPath = UIBezierPath()
    leftMaskPath.moveToPoint(CGPoint(x: -2 * maskReferenceSize, y: 0))
    leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize + (maskReferenceSize / 10) - spaceBetween, y: 0))
    leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize - (maskReferenceSize / 10) - spaceBetween, y: maskReferenceSize))
    leftMaskPath.addLineToPoint(CGPoint(x: -2 * maskReferenceSize, y: maskReferenceSize))
    leftMaskPath.closePath()
    let leftMask = CAShapeLayer()
    leftMask.path = leftMaskPath.CGPath
    left.layer.mask = leftMask

    let rightMaskPath = UIBezierPath()
    rightMaskPath.moveToPoint(CGPoint(x: 3 * maskReferenceSize, y: 0))
    rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / 10) + spaceBetween, y: 0))
    rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / -10) + spaceBetween, y: maskReferenceSize))
    rightMaskPath.addLineToPoint(CGPoint(x: 3 * maskReferenceSize, y: maskReferenceSize))
    rightMaskPath.closePath()
    let rightMask = CAShapeLayer()
    rightMask.path = rightMaskPath.CGPath
    right.layer.mask = rightMask
}

private func fn_pushStrings() {
    NSLocalizedString("P001", value: "New Poll", comment: "Push title for when a friend posts a poll")
    NSLocalizedString("P002", value: "%1$@ needs help", comment: "Push message for when a friend posts a poll without caption")
    NSLocalizedString("P003", value: "%1$@ needs help: \"%1$@\"", comment: "Push message for when a friend posts a poll with caption")
}

// MARK: - Extensions

extension Reachability {
    /// Helper to test internet reachability
    class func fn_reachable() -> Bool {
        return reachabilityForInternetConnection().isReachable()
    }
}

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

    /// rgb(224, 242, 240)
    class func fn_lighter(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 0.87843137254901960784313725490196078431372549019608, green: 0.94901960784313725490196078431372549019607843137255, blue: 0.94117647058823529411764705882352941176470588235294, alpha: alpha)
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

    /// rgb(187, 186, 194)
    class func fn_placeholder(alpha: CGFloat = 1) -> UIColor { // TODO: Calculate
        return UIColor(red: 187/255.0, green: 186/255.0, blue: 194/255.0, alpha: alpha)
//        return UIColor(red: 0.82745098039215686274509803921568627450980392156863, green: 0.82745098039215686274509803921568627450980392156863, blue: 0.82745098039215686274509803921568627450980392156863, alpha: alpha) 211
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

        let resizeScale = maxHeight / size.height

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
        return count(self)
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
            layer.rasterizationScale = UIScreen.mainScreen().scale
            layer.shouldRasterize = newValue
        }
    }
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

    /// Set an activity indicator view as subview, covering everything and returns it.
    func fn_setLoading(style: UIActivityIndicatorViewStyle = .WhiteLarge, color: UIColor = UIColor.grayColor(), background: UIColor = UIColor.whiteColor()) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: style)
        activityIndicator.color = color
        activityIndicator.backgroundColor = background
        activityIndicator.startAnimating()
        activityIndicator.frame = bounds
        activityIndicator.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        activityIndicator.opaque = true
        addSubview(activityIndicator)
        return activityIndicator
    }
}

extension UIImageView {
    /// Adjusts the image view aspect ratio constraint to the size of the image
    func fn_setAspectRatio(image newImage: UIImage?, needsLayout: Bool = true) {

        if let correctImage = newImage ?? image {
            // Remove old aspect ratio
            if NSLayoutConstraint.respondsToSelector("deactivateConstraints:") {
                NSLayoutConstraint.deactivateConstraints(constraints())
            } else {
                removeConstraints(constraints())
            }

            // Add new
            addConstraint(NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: correctImage.size.width / correctImage.size.height, constant: 0))
            if needsLayout {
                setNeedsLayout()
            }
        }
    }
}

extension NSError {
    convenience init(fn_code: FNErrorCode, userInfo: [NSObject:AnyObject]? = nil) {
        self.init(domain: FNErrorDomain, code: fn_code.rawValue, userInfo: userInfo)
    }
}

extension UIViewController {
    var fn_tabBarController: TabBarController {
        return tabBarController as! TabBarController
    }
}

extension UINavigationController {
    public override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return topViewController.preferredStatusBarUpdateAnimation()
    }
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return topViewController.preferredStatusBarStyle()
    }
    public override func prefersStatusBarHidden() -> Bool {
        return topViewController.prefersStatusBarHidden()
    }
}

// MARK: - Classes

class FNAnalytics {

    class func logError(error: NSError?, location: String) -> Bool {
        if let error = error {
            var params = ["Domain": error.domain, "Code": "\(error.code)", "Location": location]
            GAI.sharedInstance().defaultTracker.send(GAIDictionaryBuilder.createExceptionWithDescription(error.description, withFatal: false).setAll(params).build() as [NSObject:AnyObject])
            params["Description"] = error.description
            FBSDKAppEvents.logEvent("Error", parameters: params)
            return true
        }
        return false
    }

    class func logRegistration(method: String?) {
        if let method = method {
            FBSDKAppEvents.logEvent(FBSDKAppEventNameCompletedRegistration, parameters: [FBSDKAppEventParameterNameRegistrationMethod: method])
        }
    }

    class func logPhoto(imageSource: String) {
        let params = ["Source": imageSource]
        FBSDKAppEvents.logEvent("Photo Saved", parameters: params)
        GAI.sharedInstance().defaultTracker.send(GAIDictionaryBuilder.createEventWithCategory("Photo Saved", action: "Source", label: nil, value: nil).setAll(params).build() as [NSObject:AnyObject])
    }

    class func logScreen(identifier: String, time: NSTimeInterval) {
        let params = ["Name": identifier]
        FBSDKAppEvents.logEvent("Screen Viewed", valueToSum: time, parameters: params)
        GAI.sharedInstance().defaultTracker.send(GAIDictionaryBuilder.createEventWithCategory("Screen Viewd", action: "Name", label: nil, value: nil).setAll(params).build() as [NSObject:AnyObject])
    }

    class func logVote(vote: Int, method: String) {
        let params = ["Vote": "\(vote)", "Method": method]
        FBSDKAppEvents.logEvent("Poll Voted", parameters: params)
        GAI.sharedInstance().defaultTracker.send(GAIDictionaryBuilder.createEventWithCategory("Vote", action: "Poll Voted", label: nil, value: nil).setAll(params).build() as [NSObject:AnyObject])
    }
}

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

/// UIImageView that gets the image and apply template rendering mode
class FNTemplateImageView: UIImageView {

    override func awakeFromNib() {
        super.awakeFromNib()

        setTemplateImage(image)
    }

    func setTemplateImage(imageTemplate: UIImage?) {
        image = imageTemplate?.imageWithRenderingMode(.AlwaysTemplate)
    }
}

/// Helper for TSMessage
class FNToast {
    class func show(#title: String, message: String? = nil, type: TSMessageNotificationType = .Message) {
        TSMessage.showNotificationWithTitle(title, subtitle: message, type: type)
    }
}

class FNViewController: UIViewController {

    private var appearDate = NSDate()

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        TSMessage.setDefaultViewController(self)
        appearDate = NSDate()
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: title)
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject:AnyObject])
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        FNAnalytics.logScreen(title!, time: -appearDate.timeIntervalSinceNow)
    }
}

class FNTableController: UITableViewController {

    private var appearDate = NSDate()

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        TSMessage.setDefaultViewController(self)
        appearDate = NSDate()
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: title)
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject:AnyObject])
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        FNAnalytics.logScreen(title!, time: -appearDate.timeIntervalSinceNow)
    }
}

class FNCollectionController: UICollectionViewController {

    private var appearDate = NSDate()

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        TSMessage.setDefaultViewController(self)
        appearDate = NSDate()
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: title)
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject:AnyObject])
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        FNAnalytics.logScreen(title!, time: -appearDate.timeIntervalSinceNow)
    }
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
    /// The operator is busy, probably from network activity.
    case Busy = 800
    /// App tried update, but there’s nothing new
    case NothingNew = 801
    /// App was online, but now is offline.
    case ConnectionLost = 802
    /// App is offline and has no cache content.
    case NoCache = 803
    /// Requests are limited. We need to save them.
    case RequestTooOften = 804
    /// Tried to load a Photo with no image URL.
    case NoPhotoURL = 805
    /// No data or data is invalid.
    case NoData = 806
    /// Reachability framework cant find remote host.
    case InternetUnreachable = 807
    /// User canceled the operation.
    case UserCanceled = 808
}

let FNFacebookReadPermissions = ["public_profile", "user_friends", "email"]

let FNLocalizedAppName = NSLocalizedString("Default.appName", value: "Fashion Now" , comment: "Default for entire app")

/// Returns "You are offline. Try again later." for English and its variants for other languages
let FNLocalizedOfflineErrorDescription = NSLocalizedString("Default.errorDescription.offline", value: "You are offline. Try again later." , comment: "Default for entire app")

/// Returns "Unknown error. Try again later." for English and its variants for other languages
let FNLocalizedUnknownErrorDescription = NSLocalizedString("Default.errorDescription.unknown", value: "Unknown error. Try again later." , comment: "Default for entire app")

/// Returns "OK" for English and its variants for other languages
let FNLocalizedOKButtonTitle = NSLocalizedString("Default.buttonTitle.ok", value: "OK" , comment: "Default OK button title for entire app")

/// Returns "Cancel" for English and its variants for other languages
let FNLocalizedCancelButtonTitle = NSLocalizedString("Default.buttonTitle.cancel", value: "Cancel" , comment: "Default Cancel button title for entire app")
