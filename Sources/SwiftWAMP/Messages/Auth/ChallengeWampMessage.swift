//
//  ChallengeWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import SwiftyJSON

/// [CHALLENGE, authMethod|string, extra|dict]
class ChallengeWampMessage: WampMessage {
    
    let authMethod: String
    let extra: [String: Any]
    
    init(authMethod: String, extra: [String: Any]) {
        self.authMethod = authMethod
        self.extra = extra
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.authMethod = payload[0] as! String
        self.extra = payload[1] as! [String: Any]
    }
    
    func marshal() -> [Any] {
        return [WampMessages.challenge.rawValue, self.authMethod, self.extra]
    }
}