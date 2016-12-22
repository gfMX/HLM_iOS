//
//  HLMPageViewController.swift
//  HotLikeMe
//
//  Created by developer on 16/11/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class HLMPageViewController: UIPageViewController, CLLocationManagerDelegate {
    
    var timer: Timer!
    var orderedViewControllersCount = 1
    var locationManager:CLLocationManager!
    
    let defaults = UserDefaults.standard
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newColoredViewController(color: "Login"),
                self.newColoredViewController(color: "Users"),
                self.newColoredViewController(color: "UserList")]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = FireConnection.sharedInstance
        
        dataSource = self
        orderedViewControllersCount = orderedViewControllers.count
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        //NotificationCenter.default.addObserver(self, selector: #selector(self.determineMyCurrentLocation), name: NSNotification.Name(rawValue: "defGPS"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let timeInterval = (defaults.double(forKey: "defSyncFrequency") * 60)
        //if defaults.bool(forKey: "defVisible"){
            print ("Requesting Location 📡")
            self.determineMyCurrentLocation()
            timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.determineMyCurrentLocation), userInfo: nil, repeats: true);
        //} else {
          //  print("❌ Default config for Visible not Found or Not Enabled")
        //}
        //print("Defaults: \(defaults)")
    }

    private func newColoredViewController(color: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "HLM\(color)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - GPS Location
    
    func determineMyCurrentLocation() {
        if defaults.bool(forKey: "defVisible"){
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            
            if CLLocationManager.locationServicesEnabled() && defaults.bool(forKey: "defGPS") {
                locationManager.startUpdatingLocation()
                //locationManager.startUpdatingHeading()
            } else {
                print("📡 Location request Stopped by the User")
            }
        } else {
              print("📡 ❌ enabled!")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        FireConnection.setCurrentLocation(location: userLocation)
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
    if FireConnection.fireUser != nil {
            //print("Location Updated")
            let fireReference = FireConnection.databaseReference.child("users").child(FireConnection.fireUser.uid).child("location_last")
            
            fireReference.child("loc_latitude").setValue(userLocation.coordinate.latitude)
            fireReference.child("loc_longitude").setValue(userLocation.coordinate.longitude)
            fireReference.child("loc_accuracy:").setValue(userLocation.horizontalAccuracy)
            fireReference.child("timestamp").setValue(userLocation.timestamp.timeIntervalSince1970 * 1000)
            fireReference.child("day").setValue(userLocation.timestamp.description)
        }
        
        print("latitude  = \(userLocation.coordinate.latitude)")
        print("longitude = \(userLocation.coordinate.longitude)")
        print("location Accuracy: \(userLocation.horizontalAccuracy) Timestamp: \(userLocation.timestamp)")
        
        manager.stopUpdatingLocation()

        /* if !defaults.bool(forKey: "defVisible"){
            timer.invalidate()
            print ("⚠️ Requesting Location 📡 Stoped")
        } */
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error on Location \(error)")
    }

}

// MARK: UIPageViewControllerDataSource
extension HLMPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllersCount > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
   
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
}

