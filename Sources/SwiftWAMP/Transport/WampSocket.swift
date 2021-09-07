//
//  WampSocket.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import Starscream

public typealias httpHeader = String
public typealias httpHeaderValue = String

open class WampSocket: WebSocketDelegate, WampTransport {
    
    public var delegate: WampTransportDelegate?
    let socket: WebSocket
    let mode: WebsocketMode
    
    fileprivate var disconnectionReason: String?
    
    public init(wsEndpoint: URL, httpHeaders: [httpHeader:httpHeaderValue]? = nil){
        var request = URLRequest(url: wsEndpoint)
        request.setValue("wamp.2.json, wamp.2.msgpack", forHTTPHeaderField: "Sec-Websocket-Protocol")
        httpHeaders?.forEach { (header: httpHeader, value: httpHeaderValue) in
            request.setValue(value, forHTTPHeaderField: header)
        }
        self.socket = WebSocket(request: request)
        //            WebSocket(url: wsEndpoint, protocols: ["wamp.2.json"])
        self.mode = .text
        self.socket.delegate = self
    }
    
    // MARK: Transport
    
    open func connect() {
        self.socket.connect()
    }
    
    open func disconnect(_ reason: String) {
        self.disconnectionReason = reason
        self.socket.disconnect()
    }
    
    open func sendData(_ data: Data) {
        if self.mode == .text {
            self.socket.write(string: String(data: data, encoding: String.Encoding.utf8)!)
        } else {
            self.socket.write(data: data)
        }
    }
    
    // MARK: WebSocketDelegate
    
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            delegate?.wampTransportDidConnect()
        case .disconnected(let reason, let code):
            delegate?.wampTransportDidDisconnect(reason, code: code)
        case .text(let string):
            if let data = string.data(using: String.Encoding.utf8) {
                delegate?.wampTransportReceivedData(data)
            }
        case .binary(let data):
            delegate?.wampTransportReceivedData(data)
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(let status):
            delegate?.wampTransportViabilityChanged(status)
        case .reconnectSuggested(let status):
            delegate?.wampTransportReconnectSuggested(status)
        case .cancelled:
            break
        case .error(let error):
            print("ERROR: \(error.debugDescription)")
        }
    }
}
