//
//  WampTransport.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

public protocol WampTransportDelegate {
    func wampTransportDidConnectWithSerializer(_ serializer: WampSerializer)
    func wampTransportDidDisconnect(_ reason: String, code: UInt16)
    func wampTransportReceivedData(_ data: Data)
}

public protocol WampTransport {
    var delegate: WampTransportDelegate? { get set }
    func connect()
    func disconnect(_ reason: String)
    func sendData(_ data: Data)
}
