//
//  RegisterWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [Register, requestId|number, options|dict, proc|string]
class RegisterWampMessage: WampMessage {
    
    let requestId: Int
    let options: [String: Any]
    let proc: String
    
    init(requestId: Int, options: [String: Any], proc: String) {
        self.requestId = requestId
        self.options = options
        self.proc = proc
    }
    
    // MARK: WampMessage protocol
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.options = payload[1] as! [String: Any]
        self.proc = payload[2] as! String
    }
    
    func marshal() -> [Any] {
        return [WampMessages.register.rawValue, self.requestId, self.options, self.proc]
    }
}
