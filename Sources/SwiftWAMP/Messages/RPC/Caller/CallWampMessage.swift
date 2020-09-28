//
//  CallWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [CALL, requestId|number, options|dict, proc|string, args|array?, kwargs|dict?]
class CallWampMessage: WampMessage {
    
    let requestId: Int
    let options: [String: Any]
    let proc: String
    let args: [Any]?
    let kwargs: [String: Any]?
    
    init(requestId: Int, options: [String: Any], proc: String, args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        self.requestId = requestId
        self.options = options
        self.proc = proc
        self.args = args
        self.kwargs = kwargs
    }
    
    /// MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.options = payload[1] as! [String: Any]
        self.proc = payload[2] as! String
        self.args = payload[safe: 3] as? [Any]
        self.kwargs = payload[safe: 4] as? [String: Any]
    }
    
    func marshal() -> [Any] {
        var marshalled: [Any] = [WampMessages.call.rawValue, self.requestId, self.options, self.proc]
        
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
