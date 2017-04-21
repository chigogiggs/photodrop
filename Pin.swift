//
//  Pin2.swift
//  photodrop
//
//  Created by chigo anyaso on 2017-04-15.
//  Copyright © 2017 chigo anyaso. All rights reserved.
//

import Foundation
import UIKit

class Pin: NSObject, MKAnnotation{
    
    var key: String!
    var coordinate: CLLocationCoordinate2D
    
    init(key: String){
         self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.key = key
    }
}
