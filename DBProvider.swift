//
//  DBProvider.swift
//  photodrop
//
//  Created by chigo anyaso on 2017-04-15.
//  Copyright © 2017 chigo anyaso. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

//
//protocol Fetchdata: class {
//    func datarecieved(contacts: [Contact])
//}

class DBProvider{
    
    private static let _instance = DBProvider()
    
//    weak var delegate: Fetchdata?
    
    private init() {}
    
    static var Instance: DBProvider {
        return _instance
    }
    
    var dbRef:  FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    var locationRef: FIRDatabaseReference {
        return dbRef.child(Constants.location)
    }
    var georef: FIRDatabaseReference {
        return dbRef.child(Constants.georef)
    }
    
}













