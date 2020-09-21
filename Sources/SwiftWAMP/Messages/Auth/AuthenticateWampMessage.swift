//
//  AuthenticateWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import SwiftyJSON

/// [AUTHENTICATE, signature|string, extra|dict]
class AuthenticateWampMessage: WampMessage {
    
    let signature: String
    let extra: [String: Any]
    
    init(signature: String, extra: [String: AnyObject]) {
        self.signature = signature
        self.extra = extra
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.signature  = payload[0] as! String
        self.extra = payload[1] as! [String: Any]
    }
    
    func marshal() -> [Any] {
        return [WampMessages.authenticate.rawValue, self.signature, self.extra]
    }
}