//
//  InvocationWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

// [INVOCATION, requestId|number, registration|number, details|dict, args|array?, kwargs|dict?]
class InvocationWampMessage: WampMessage {
    
    let requestId: Int
    let registration: Int
    let details: [String: Any]
    
    let args: [Any]?
    let kwargs: [String: Any]?
    
    init(requestId: Int, registration: Int, details: [String: Any], args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        self.requestId = requestId
        self.registration = registration
        self.details = details
        
        self.args = args
        self.kwargs = kwargs
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.registration = payload[1] as! Int
        self.details = payload[2] as! [String: Any]
        self.args = payload[safe: 3] as? [Any]
        self.kwargs = payload[safe: 4] as? [String: Any]
    }
    
    func marshal() -> [Any] {
        var marshalled: [Any] = [WampMessages.invocation.rawValue, self.requestId, self.registration, self.details]
        
        if let args = self.args {
            marshalled.append(args)
            if let kwargs = self.kwargs {
                marshalled.append(kwargs)
            }
        } else {
            if let kwargs = self.kwargs {
                marshalled.append([])
                marshalled.append(kwargs)
            }
        }
        
        return marshalled
    }
}
