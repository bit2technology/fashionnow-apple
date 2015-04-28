//
//  AppDelegate.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-29.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {

        // App basic configuration
        window!.tintColor = UIColor.fn_tint()

        // Register subclasses
        // This is because overriding class function "load()" doesn’t work on Swift 1.2+
        ParseInstallation.registerSubclass()
        ParsePhoto.registerSubclass()
        ParsePoll.registerSubclass()
        ParseReport.registerSubclass()
        ParseUser.registerSubclass()
        ParseVote.registerSubclass()

        // Parse pre configuration
        Parse.enableLocalDatastore()
        ParseCrashReporting.enable()
        
        // Parse configuration
        #if DEBUG
        Parse.setApplicationId("AIQ4OyhhFVequZa6eXLCDdEpxu9qE0JyFkkfczWw", clientKey: "4dMOa5Ts1cvKVcnlIv2E4wYudyN7iJoH0gQDxpVy")
        #else
        Parse.setApplicationId("Yiuaalmc4UFWxpLHfVHPrVLxrwePtsLfiEt8es9q", clientKey: "60gioIKODooB4WnQCKhCLRIE6eF1xwS0DwUf3YUv")
        #endif
        ParseUser.enableAutomaticUser()
        ParseUser.enableRevocableSessionInBackgroundWithBlock { (error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Enable Revocable Session")
        }
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)

        // Analytics
        // Parse/Facebook
        if application.applicationState != .Background {
            PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
        }
        // Google
        let tracker = GAI.sharedInstance().trackerWithTrackingId("UA-62043366-1")
        tracker.set("&uid", value: ParseUser.current().objectId)

        // Push notifications
        if application.respondsToSelector("registerUserNotificationSettings:") {
            // Register for Push Notitications, if running iOS 8 and later
            let settings = UIUserNotificationSettings(forTypes:.Alert | .Badge | .Sound, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }

        // Observe login change and update installation
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

        // Clean image cache
        SDImageCache.sharedImageCache().cleanDiskWithCompletionBlock(nil)

        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        }

        // TODO: Open specific poll
        return false
    }

    func applicationDidBecomeActive(application: UIApplication) {

        // Facebook Analytics
        FBSDKAppEvents.activateApp()

        // Erase badge number, set userID and update location
        let install = ParseInstallation.currentInstallation()
        install.badge = 0
        install.userId = ParseUser.current().objectId
        switch CLLocationManager.authorizationStatus() {
        default:
            // Get aproximate location with https://freegeoip.net/
            NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "https://freegeoip.net/json")!, completionHandler: { (data, response, error) -> Void in
                if FNAnalytics.logError(error, location: "AppDelegate: Location From IP Download") {
                    return
                }
                var jsonError: NSError?
                let geoInfo = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as? [String: AnyObject]
                if FNAnalytics.logError(jsonError, location: "AppDelegate: Location From IP Serialization") {
                    return
                }
                let latitude = geoInfo!["latitude"] as? Double
                let longitude = geoInfo!["longitude"] as? Double
                if latitude != nil && longitude != nil {
                    install.location = PFGeoPoint(latitude: latitude!, longitude: longitude!)
                    install.saveEventually { (succeeded, error) -> Void in
                        FNAnalytics.logError(error, location: "AppDelegate: Location From IP Save")
                    }
                }
            }).resume()
        }
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        SDImageCache.sharedImageCache().clearMemory()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /// Called every login or logout
    func loginChanged(notification: NSNotification) {

        // Clear caches
        let imageCache = SDImageCache.sharedImageCache()
        imageCache.clearDisk()
        imageCache.clearMemory()
        PFObject.unpinAllObjectsInBackgroundWithBlock { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Login Changed Unpin")
        }

        // Register new user ID in installation on login change
        let install = ParseInstallation.currentInstallation()
        let currentUser = ParseUser.current()
        install.userId = currentUser.objectId
        install.saveEventually { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Login Changed Save")
        }

        // Update analytics
        GAI.sharedInstance().defaultTracker.set("&uid", value: currentUser.objectId)
    }

    // MARK: Push notifications

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current installation and send it to Parse
        let install = ParseInstallation.currentInstallation()
        install.setDeviceTokenFromData(deviceToken)
        install.saveEventually { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Register Notification Save")
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        FNAnalytics.logError(error, location: "AppDelegate: Register Notification Fail")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {

        // FIXME: Error with JSON notification
        NSLog("handlePush?")
        PFPush.handlePush(userInfo)
        NSLog("pushHandled")
        if application.applicationState == .Inactive {
            // The application was just brought from the background to the foreground,
            // so we consider the app as having been "opened by a push notification."
            NSLog("trackPush?")
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
            NSLog("pushTracked")
        }

        // TODO: Open specific poll
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.application(application, didReceiveRemoteNotification: userInfo)
    }
}