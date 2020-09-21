//
//  ErrorWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [ERROR, requestType|number, requestId|number, details|dict, error|string, args|array?, kwargs|dict?]
class ErrorWampMessage: WampMessage {
    let requestType: WampMessages
    let requestId: Int
    let details: [String: Any]
    let error: String
    
    let args: [Any]?
    let kwargs: [String: Any]?
    
    init(requestType: WampMessages, requestId: Int, details: [String: Any], error: String, args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        self.requestType = requestType
        self.requestId = requestId
        self.details = details
        self.error = error
        self.args = args
        self.kwargs = kwargs
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestType = WampMessages(rawValue: payload[0] as! Int)!
        self.requestId = payload[1] as! Int
        self.details = payload[2] as! [String: Any]
        self.error = payload[3] as! String
        
        self.args = payload[safe: 4] as? [Any]
        self.kwargs = payload[safe: 5] as? [String: Any]
    }
    
    func marshal() -> [Any] {
        var marshalled: [Any] = [WampMessages.error.rawValue, self.requestType.rawValue, self.requestId, self.details, self.error]
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
