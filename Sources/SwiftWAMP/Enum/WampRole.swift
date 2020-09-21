//
//  WampRole.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

enum WampRole: String {
    // Client roles
    case Caller = "caller"
    case Callee = "callee"
    case Subscriber = "subscriber"
    case Publisher = "publisher"
    
    // Route roles
    case Broker = "broker"
    case Dealer = "dealer"
}
