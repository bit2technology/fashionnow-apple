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

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {

        // Register subclasses
        // This is because overriding class function "load()" doesn't work on Swift 1.2+
        ParseInstallation.registerSubclass()
        ParsePhoto.registerSubclass()
        ParsePoll.registerSubclass()
        ParseUser.registerSubclass()
        ParseVote.registerSubclass()

        return true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {

        // App basic configuration
        window?.tintColor = UIColor.fn_tintColor()

        // Parse pre configuration
        Parse.enableLocalDatastore()
        ParseCrashReporting.enable()
        
        // Parse configuration
        Parse.setApplicationId("Yiuaalmc4UFWxpLHfVHPrVLxrwePtsLfiEt8es9q", clientKey: "60gioIKODooB4WnQCKhCLRIE6eF1xwS0DwUf3YUv")
        ParseUser.enableAutomaticUser()
        PFFacebookUtils.initializeFacebook()

        // Analytics
        if application.applicationState != .Background {
            PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
        }

        // Logout if current user is invalid (is not anonymous and hasn't password or valid email)
        let currentUser = ParseUser.currentUser()
        if !currentUser.isValid {
            ParseUser.logOut()
        }

        // Erase badge number, set userID and update location
        let currentInstallation = ParseInstallation.currentInstallation()
        currentInstallation.badge = 0
        currentInstallation.userId = currentUser.objectId
        // Get aproximate location with https://freegeoip.net/
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "https://freegeoip.net/json")!, completionHandler: { (data, response, error) -> Void in
            let geoInfo = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String: AnyObject]
            let latitude = geoInfo?["latitude"] as? Double
            let longitude = geoInfo?["longitude"] as? Double
            if latitude != nil && longitude != nil {
                currentInstallation.location = PFGeoPoint(latitude: latitude!, longitude: longitude!)
                currentInstallation.saveEventually(nil)
            }
        }).resume()

        // Push notifications
        if application.respondsToSelector("registerUserNotificationSettings:") {
            // Register for Push Notitications, if running iOS 8
            let settings = UIUserNotificationSettings(forTypes:.Alert | .Badge | .Sound, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }

        // Observe login change and update installation
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)

        // Clean cache
        SDImageCache.sharedImageCache().cleanDiskWithCompletionBlock(nil)

        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication, withSession: PFFacebookUtils.session())
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())
        FBAppEvents.activateApp()
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        SDImageCache.sharedImageCache().clearMemory()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /// Called every login or logout
    func loginChanged(notification: NSNotification) {
        PFObject.unpinAllObjectsInBackgroundWithBlock(nil)
        
        // Register new user ID in installation on login change
        let currentInstallation = ParseInstallation.currentInstallation()
        currentInstallation.userId = ParseUser.currentUser().objectId
        currentInstallation.saveEventually(nil)
    }

    // MARK: Push notifications

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current installation and send it to Parse
        let currentInstallation = ParseInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveEventually(nil)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if application.applicationState == .Inactive {
            // The application was just brought from the background to the foreground,
            // so we consider the app as having been "opened by a push notification."
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        }
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.application(application, didReceiveRemoteNotification: userInfo)
    }
}