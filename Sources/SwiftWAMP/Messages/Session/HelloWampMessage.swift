//
//  HelloWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [HELLO, realm|string, details|dict]
class HelloWampMessage: WampMessage {
    
    let realm: String
    let details: [String: Any]
    
    init(realm: String, details: [String: Any]) {
        self.realm = realm
        self.details = details
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.realm = payload[0] as! String
        self.details = payload[1] as! [String: Any]
    }
    
    func marshal() -> [Any] {
        return [WampMessages.hello.rawValue, self.realm, self.details]
    }
}
