//
//  WampTransport.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

public protocol WampTransportDelegate {
    func wampTransportDidConnect()
    func wampTransportDidDisconnect(_ reason: String, code: UInt16)
    func wampTransportReceivedData(_ data: Data)
    func wampTransportViabilityChanged(_ isViable: Bool)
    func wampTransportReconnectSuggested(_ betterPathAvailable: Bool)
}

public protocol WampTransport {
    var delegate: WampTransportDelegate? { get set }
    func connect()
    func disconnect(_ reason: String)
    func sendData(_ data: Data)
}
