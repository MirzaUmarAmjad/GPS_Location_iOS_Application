//
//  AppDelegate.swift
//  GPSLocationApp
//
//  Created by Umar Amjad on 15/09/2020.
//  Copyright © 2020 Umar Amjad. All rights reserved.
//

import UIKit
import CoreLocation
import MQTTClient


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate {
    
    
    var window: UIWindow?
    var locationManager = CLLocationManager()
    var backgroundUpdateTask: UIBackgroundTaskIdentifier!
    var bgtimer = Timer()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var current_time = NSDate().timeIntervalSince1970
    var dictCoordinates : NSMutableDictionary = [:]
    var arrCoordinates : NSMutableArray = []
    var didGotNotification : Bool = false
    
    var newLongitude: Double = 0.0
    var newLatitude: Double = 0.0
    var oldLongitude: Double = 0.0
    var oldLatitude: Double = 0.0
    
    
    //MQTT variable
    let MQTT_HOST = "next.nanolink.com" // or IP address e.g. "192.168.0.194"
    let MQTT_PORT: UInt32 = 1883
    private var transport = MQTTCFSocketTransport()
    fileprivate var session = MQTTSession()
    fileprivate var completion: (()->())?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.startMonitoringSignificantLocationChanges()
        
        //MATT code
        //MQTT
        self.session?.delegate = self
        self.transport.host = MQTT_HOST
        self.transport.port = MQTT_PORT
        session?.transport = transport
        session?.keepAliveInterval = 1000
        
        connectMQTT()
        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Entering Backround")
        self.doBackgroundTask()
    }
    
    func doBackgroundTask() {
        
        DispatchQueue.main.async {
            
            self.beginBackgroundUpdateTask()
            
            //            self.StartupdateLocation()
            //self.updateLocation()
            
            self.bgtimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(AppDelegate.bgtimer(_:)), userInfo: nil, repeats: true)
            RunLoop.current.add(self.bgtimer, forMode: .default)
            RunLoop.current.run()
            
            //            self.endBackgroundUpdateTask()
            
        }
    }
    
    func beginBackgroundUpdateTask() {
        self.backgroundUpdateTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundUpdateTask()
        })
    }
    
    func endBackgroundUpdateTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundUpdateTask)
        self.backgroundUpdateTask = .invalid
    }
    
//    func StartupdateLocation() {
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
//        locationManager.distanceFilter = kCLDistanceFilterNone
//        locationManager.requestAlwaysAuthorization()
//        locationManager.allowsBackgroundLocationUpdates = true
//        locationManager.pausesLocationUpdatesAutomatically = false
//
//        locationManager.startUpdatingLocation()
//        locationManager.startMonitoringSignificantLocationChanges()
//    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while requesting new coordinates")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.latitude = locValue.latitude
        self.longitude = locValue.longitude
        
        if UserDefaults.standard.mutableArrayValue(forKey: "arrayOfDicts").count != 0
        {
            arrCoordinates = UserDefaults.standard.mutableArrayValue(forKey: "arrayOfDicts")
        }
        
       
//        dictCoordinates = [:]
//        dictCoordinates.setValue(self.longitude, forKey: "longitude")
//        dictCoordinates.setValue(self.latitude, forKey: "latitude")
//
//
//
//        print(dictCoordinates)
//
//        arrCoordinates.add(dictCoordinates)
//
        UserDefaults.standard.set((self.latitude), forKey: "latitude")
        UserDefaults.standard.set((self.longitude), forKey: "longitude")
        
        
       
        
        
        
        
    }
    
    @objc func bgtimer(_ timer:Timer!){
        print("this is a bgtimer function")
        self.updateLocation()
    }
    
    func updateLocation() {
        //        self.didGotNotification = false
        self.locationManager.startMonitoringSignificantLocationChanges()
        let lat = UserDefaults.standard.object(forKey: "latitude")
        let long = UserDefaults.standard.object(forKey: "longitude")
        print("lat: ", lat!)
        print("long: ", long!)
        
        newLatitude = lat as! Double
        newLongitude = long as! Double
        
        let coordinatePickup = CLLocation(latitude: oldLatitude, longitude: oldLongitude)
        let coordinateDestination = CLLocation(latitude: newLatitude, longitude:newLongitude)
        
        let distanceInMeters = coordinatePickup.distance(from: coordinateDestination)
        
        print(distanceInMeters)
        
        
        if distanceInMeters >= 500{
            //MQTT code
            
            print("check return before public")
            if session?.status != .connected {
                connectMQTT()
            }
            print("check return public ")
            let strCoordinates = String(format: "Latitude = %f and Longitude = %f", lat as! Double , long as! Double)
            
            publishMessage(strCoordinates, onTopic: "test/message1")
            
            oldLatitude = newLatitude
            oldLongitude = newLongitude
            
            dictCoordinates.setValue(newLongitude, forKey: "longitude")
            dictCoordinates.setValue(newLatitude, forKey: "latitude")
            
            print(dictCoordinates)
            
            arrCoordinates.add(dictCoordinates)
            
            UserDefaults.standard.set(arrCoordinates, forKey: "arrayOfDicts")
            UserDefaults.standard.synchronize()
            
            NotificationCenter.default.post(name: .didReceiveData, object: dictCoordinates)
            
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "arrCoordinates") , object: arrCoordinates)
            
        }
        
        
        
        
    }
    
    
    
    
    
    
    //MQTT code
    
    func connectMQTT() {
        updateUI(for: self.session?.status ?? .created)
        session?.connect() { error in
            print("connection completed with status \(String(describing: error?.localizedDescription))")
            if error != nil {
                self.updateUI(for: self.session?.status ?? .created)
            } else {
                self.updateUI(for: self.session?.status ?? .error)
            }
        }
    }
    
    private func publishMessage(_ message: String, onTopic topic: String)
    {
        print("publish code")
        session?.publishData(message.data(using: .utf8, allowLossyConversion: false), onTopic: topic, retain: false, qos: .atMostOnce)
    }
    
    private func subscribe() {
        self.session?.subscribe(toTopic: "test/message", at: .exactlyOnce) { error, result in
            print("subscribe result error \(String(describing: error)) result \(result!)")
        }
    }
    
    private func updateUI(for clientStatus: MQTTSessionStatus) {
        DispatchQueue.main.async {
            switch clientStatus {
            case .connected:
                print("Connected")
                self.publishMessage("", onTopic: "test/message")
                
            case .connecting,
                 .created:
                print ("Trying to connect...")
            default:
                print ("Connetion Failed...")
            }
        }
    }
    
    
}


extension AppDelegate: MQTTSessionManagerDelegate, MQTTSessionDelegate {
    
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        if let msg = String(data: data, encoding: .utf8) {
            print("topic \(topic!), msg \(msg)")
        }
    }
    
    
}


