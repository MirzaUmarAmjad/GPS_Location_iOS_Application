//
//  ViewController.swift
//  GPSLocationApp
//
//  Created by Umar Amjad on 15/09/2020.
//  Copyright © 2020 Umar Amjad. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var tblCords: UITableView!
   
    
    var rows : Int = 0
    var arrCords : NSMutableArray = []
    var savedArrCords : NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("enter viewDidLoad")
        
        savedArrCords = UserDefaults.standard.mutableArrayValue(forKey: "arrayOfDicts")
        rows = self.savedArrCords.count
        if self.savedArrCords.count > 0
        {
            print(UserDefaults.standard.mutableArrayValue(forKey: "arrayOfDicts"))
            print(savedArrCords)
            self.tblCords.reloadData()
        }
        
        
        //notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: .didReceiveData, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveDataForArray(_:)), name: NSNotification.Name(rawValue: "arrCoordinates"), object: nil)
        
        
       
        
    }
    
    
    
    
    
    
    @objc func onDidReceiveDataForArray(_ notification:Notification) {
        
     
        //savedArrCords = UserDefaults.standard.object(forKey: "arrayOfDicts") as! NSMutableArray
        savedArrCords = UserDefaults.standard.mutableArrayValue(forKey: "arrayOfDicts")
        rows = savedArrCords.count
        
        self.tblCords.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell  = self.tblCords.dequeueReusableCell(withIdentifier: "CordCell", for: indexPath)
        
        if self.savedArrCords.count > 0
        {
            let lblLatitude = cell.viewWithTag(555) as! UILabel
            let lblLongitude = cell.viewWithTag(666) as! UILabel
            
            let objLocation = self.savedArrCords[indexPath.row] as! NSDictionary
            
            
            lblLatitude.text = "Latitude =" + String(objLocation.value(forKey: "latitude") as! Double)
            lblLongitude.text = "Longitude =" + String(objLocation.value(forKey: "longitude") as! Double)
            //                String(format: "Longitude = %f", objLocation.value(forKey: "longitude")as! Double)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
    @objc func onDidReceiveData(_ notification:Notification) {
        
        
       
        
        let obj  =  notification.object! as! NSMutableDictionary
        
        print(notification.object!)
        let notificationLatitude = obj.value(forKey: "latitude")! as! Double
        let notificationLongitude = obj.value(forKey: "longitude")! as! Double
        
        
        print(" notification latitude:", notificationLatitude)
        print(" notification longitude:", notificationLongitude)
        
        
        let strCoordinates = String(format: "Latitude = %f and Longitude = %f", notificationLatitude , notificationLongitude)
        
        
        
        
    }
    
}





extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
}
