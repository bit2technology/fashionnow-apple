//
//  UsersMapController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-05-18.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import MapKit

class UsersMapController: FNViewController, CCHMapClusterControllerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    private var clusterController: CCHMapClusterController!

    @IBAction func dismiss(sender: UITabBarItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func mapClusterController(mapClusterController: CCHMapClusterController!, titleForMapClusterAnnotation mapClusterAnnotation: CCHMapClusterAnnotation!) -> String! {
        return "\(mapClusterAnnotation.annotations.count) Devices"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        clusterController = CCHMapClusterController(mapView: mapView)
        clusterController.delegate = self

        // Do any additional setup after loading the view.

        PFCloud.callFunctionInBackground("deviceLocations", withParameters: nil) { (results, error) -> Void in
            var annots = [UserAnnotation]()
            for installation in results as! [ParseInstallation] {
                annots.append(UserAnnotation(geoPoint: installation.location!))
            }
            self.clusterController.addAnnotations(annots, withCompletionHandler: { () -> Void in
                self.navigationItem.title = "\(annots.count) Devices"
                self.navigationItem.titleView = nil
            })
        }

//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//            let query = PFQuery(className: ParseInstallation.parseClassName())
//                .selectKeys([ParseInstallationLocationKey])
//            query.limit = ParseQueryLimit
//
//            var error: NSError?
//            var locations = [UserAnnotation]()
//            var jump = 0
//
//            while error == nil {
//                if let results = query.findObjects(&error) as? [ParseInstallation] {
//                    if results.count == 0 {
//                        break
//                    }
//                    jump += results.count
//
//                    for result in results {
//                        if let location = result.location {
//                            locations.append(UserAnnotation(latitude: location.latitude, longitude: location.longitude))
//                        }
//                    }
//
//                } else {
//                    break
//                }
//            }
//
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.clusterController.addAnnotations(locations, withCompletionHandler: { () -> Void in
//                    self.navigationItem.title = "\(locations.count) Devices"
//                    self.navigationItem.titleView = nil
//                })
//            })
//        })
    }
}

class UserAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D

    init(geoPoint: PFGeoPoint) {
        coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
    }
}