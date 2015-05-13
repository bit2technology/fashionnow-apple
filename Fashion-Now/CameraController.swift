//
//  CameraController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-05-13.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class CameraController: FNViewController {

    private weak var camWrapper: UIViewController!
    let fasttttCam = FastttCamera.new()

    @IBAction func cancel(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func takePicture(sender: UIButton) {
        fasttttCam.takePicture()
        view.addSubview(view.snapshotViewAfterScreenUpdates(false))
        let whiteView = UIView(frame: view.bounds)
        whiteView.backgroundColor = UIColor.fn_white()
        whiteView.userInteractionEnabled = true
        view.addSubview(whiteView)
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            whiteView.alpha = 0
        })
    }

    // MARK: UIViewController

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        fasttttCam.view.frame = camWrapper.view.bounds
        camWrapper.fastttAddChildViewController(fasttttCam)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {

        case "Camera Wrapper":
            camWrapper = segue.destinationViewController as! UIViewController

        default:
            break
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}