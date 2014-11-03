//
//  RootController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-03.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class RootController: UIViewController {
    
    weak var innerTabBarController: UITabBarController!
    
    @IBOutlet weak var contentBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var tabBarBottomMargin: NSLayoutConstraint!
    
    private var cleanInterface = false
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let unwrappedSegueId = segue.identifier {
            
            switch unwrappedSegueId {
                
            case "Tab Bar Controller":
                innerTabBarController = segue.destinationViewController as UITabBarController
                
            default:
                return
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if respondsToSelector("traitCollection") {
            cleanInterface = (traitCollection.verticalSizeClass == .Compact)
        } else {
            cleanInterface = (interfaceOrientation.isLandscape && UIDevice.currentDevice().userInterfaceIdiom == .Phone)
        }
        
        tabBarBottomMargin.constant = (cleanInterface ? -tabBar.frame.height : 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        innerTabBarController.tabBar.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBar.items = innerTabBarController.tabBar.items
        tabBar.selectedItem = innerTabBarController.tabBar.selectedItem
    }
}
