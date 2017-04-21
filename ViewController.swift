//
//  ViewController.swift
//  photodrop
//
//  Created by chigo anyaso on 2017-04-14.
//  Copyright © 2017 chigo anyaso. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GeoFire
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import AudioToolbox

class ViewController: UIViewController, UIAlertViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var activityindicator: UIActivityIndicatorView!
    @IBOutlet weak var cancel: UIButton!
    var alertstatus = "off"
    @IBOutlet weak var dropoutlet: UIBarButtonItem!
    @IBAction func cnacelbutton(_ sender: Any) {
        swipe()
    }
    var geofire : GeoFire! = nil
    var inexchange = false
    var annotations: Dictionary<String, Pin> = Dictionary(minimumCapacity: 8)
    let locationManager = CLLocationManager()
    let imagepicker = UIImagePickerController()
    var lastexchangedkeyValue = [String]()
    @IBOutlet weak var mapview: MKMapView!
    @IBOutlet weak var foundimage: UIImageView!
    var regionquery : GFRegionQuery?
    var foundquery: GFCircleQuery?
    var lastexchangekeyfound: String?
    var lastexchangelocationfound: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagepicker.sourceType = .photoLibrary
        imagepicker.delegate = self
        activityindicator.alpha = 0
        cancel.alpha = 0
        activityindicator.frame = CGRect(x: Int(activityindicator.center.x), y: Int(activityindicator.center.y), width: 200, height: 200)
        lastexchangedkeyValue = []
        mapview.mapType = .satellite
    }

    @IBAction func dropphoto(_ sender: Any) {
        present(imagepicker, animated: true, completion: nil)
        print("Dropping Photo")
        
    }
    override func viewDidAppear(_ animated: Bool) {
        locationManager.requestWhenInUseAuthorization()
        self.mapview.userLocation.addObserver(self, forKeyPath: "location", options: NSKeyValueObservingOptions(), context: nil)
        
        
        geofire = GeoFire(firebaseRef: DBProvider.Instance.georef)

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        inexchange = false
        dropoutlet.isEnabled = true
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
        
        self.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
//        let thumbnail = image.resizedImage(with: UIViewContentMode.scaleAspectFit, bounds: CGSize(width: 400, height: 400), interpolationQuality: CGInterpolationQuality.high)
        activityindicator.alpha = 1
        let bckView = backgrounduiviewforactivatorindicator()
        print("gonna start jpg comPRESSION NOW")
        let imgdata = UIImageJPEGRepresentation(image, 1)
            print("DONE COMPRESSIONV1")
        let base64EncodedImage = imgdata?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithLineFeed)
            print("DONE COMPRESSION 2")
        if inexchange{
            print("self.lastEXCHANGEKEYVALUE IS \(self.lastexchangedkeyValue.count) ")
            for e in self.lastexchangedkeyValue{
                print("\(e.characters.count) \n")
            }
            print("IS IN EXCHANGE MODE")
            DBProvider.Instance.locationRef.child(self.lastexchangekeyfound!).observe(.value, with: {(snapshot) -> Void in
                print("GOT SNAPSHOT")
                DBProvider.Instance.locationRef.child(self.lastexchangekeyfound!).removeAllObservers()
                if let imageinbase64 = snapshot.value as? String {
                  let existingimageinBASE64 = imageinbase64//self.lastexchangedkeyValue//imageinbase64[key] as! String
//                print("IMAGE IN BASE 64 is  \(existingimageinBASE64)")
                let existingimagedata = NSData(base64Encoded: existingimageinBASE64, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
                let image = UIImage(data: existingimagedata! as Data)
            
                self.foundimage.image = image
                self.activityindicator.alpha = 0
                self.dropoutlet.isEnabled = true

                bckView.removeFromSuperview()
                self.cancel.alpha = 1
                self.foundimage.isHidden = false
                        
                UIView.animate(withDuration: 0.5, animations: {
                    () -> Void in
                    self.foundimage.alpha = 1
                    let layer = self.foundimage.layer
                    layer.shadowColor = UIColor.black.cgColor
                    layer.shadowRadius = 10.0
                    layer.shadowOffset = CGSize(width: 10, height: 5)
                    layer.shadowOpacity = 0.8
                })}
                
                            DBProvider.Instance.locationRef.updateChildValues([self.lastexchangekeyfound! : base64EncodedImage!])
            })
        }else {
            let uniquerefrence = DBProvider.Instance.locationRef.childByAutoId()
            uniquerefrence.setValue(base64EncodedImage)
            

            let key = uniquerefrence.key
            let _ = mapview.userLocation.location
            geofire!.setLocation(mapview.userLocation.location, forKey: key)
            print("fdone!")
            activityindicator.alpha = 0
        }
        }
        
        inexchange = false
        dropoutlet.isEnabled = true
        alertstatus = "off"
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (self.mapview.showsUserLocation && self.mapview.userLocation.location != nil){
            
            let span = MKCoordinateSpanMake(0.00125, 0.00125)
            let region = MKCoordinateRegionMake((self.mapview.userLocation.location?.coordinate)!,  span)
            
            self.mapview.setRegion(region, animated: true)
            
            if regionquery == nil{
                regionquery = geofire?.query(with: region)
                regionquery?.observe(GFEventType.keyEntered, with: {
                    (key: String!, location: CLLocation!) in
                    let annotation = Pin(key: key)
                    annotation.coordinate = location.coordinate
                    self.mapview.addAnnotation(annotation)
                    self.annotations[key] = annotation
                    
                })
                
                regionquery?.observe(GFEventType.keyExited, with: {
                    (key: String!, location: CLLocation!) -> Void in
                    self.mapview.removeAnnotation(self.annotations[key]!)
                    self.annotations[key] = nil
                    
                })

            
            }
            
            if foundquery == nil {
                foundquery = geofire?.query(at: self.mapview.userLocation.location, withRadius: 0.05//25
                )
                
                foundquery!.observe(GFEventType.keyEntered, with: {
                    (key: String!, location: CLLocation!) -> Void in
                    self.lastexchangelocationfound = location
                    if self.alertstatus == "off" {
                        self.alert(title: "You found a Drop", message: "You can view the photo by tapping exchange a new photo", key: key)
                    }
                }
                    )
            }else {
                
                foundquery?.center = self.mapview.userLocation.location
            }
        }
    }
    
    func alert(title: String, message: String, key : String?){
        alertstatus = "on"
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Exchange", style: .default, handler: { action in
            if action.style == .default{
                print("Exchange!!!!!!!!!!!")
                self.inexchange = true
                if key != nil{
                    
                    self.lastexchangekeyfound = key
                    print("key is \(String(describing: self.lastexchangekeyfound))")
                    DBProvider.Instance.locationRef.child(self.lastexchangekeyfound!).observe(.value, with: {(snapshot) -> Void in
                      print("observing value")
                        if let contents = snapshot.value as? String{
//                            print("contents is \(contents)")
                           self.lastexchangedkeyValue.append(contents)
                            //                            print("got last exchange key value!! \(String(describing: self.lastexchangedkeyValue))")
                            
                        }
                    })

                }
                self.dropphoto(self)
            }
        }))
            
        alert.addAction(UIAlertAction(title: "Not Here", style: .default, handler: { action in
            if action.style == .default{
                print("Not Here!!!!!!!!!!!")
                self.dropoutlet.isEnabled = true
                self.alertstatus = "off"
                
            }
        }))
        self.present(alert, animated: true, completion: nil)

    }
    

    @IBAction func swiped(_ sender: Any) {
       swipe()
    }
    func swipe(){
        UIView.animate(withDuration: 1.5, animations: {
            
            self.foundimage.alpha = 0
            self.cancel.alpha = 0
            
            
        })
    }
    
    func backgrounduiviewforactivatorindicator() -> UIView{
        dropoutlet.isEnabled = false
        let vieww = UIImageView(frame: view.bounds)
        
        view.addSubview(vieww)
        view.bringSubview(toFront: activityindicator)
        return vieww
    }
}


























