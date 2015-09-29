//
//  CameraController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-05-13.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

class CameraController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private weak var camWrapper: UIViewController!
    let fastttCam = FastttFilterCamera()

    @IBAction func cancel(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func filters(sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .PhotoLibrary
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }

    @IBAction func takePicture(sender: UIButton) {
        fastttCam.takePicture()
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

        fastttCam.view.frame = camWrapper.view.bounds
        camWrapper.fastttAddChildViewController(fastttCam)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {

        case "Camera Wrapper":
            camWrapper = segue.destinationViewController 

        default:
            break
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        fastttCam.filterImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
