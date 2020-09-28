//
//  WampSocket.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import Starscream

open class WampSocket: WebSocketDelegate, WampTransport {
    
    public var delegate: WampTransportDelegate?
    let socket: WebSocket
    let mode: WebsocketMode
    
    fileprivate var disconnectionReason: String?
    
    public init(wsEndpoint: URL){
        var request = URLRequest(url: wsEndpoint)
        request.setValue("wamp.2.json, wamp.2.msgpack", forHTTPHeaderField: "Sec-Websocket-Protocol")
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
    
    // TODO: Starscream V3.0.0
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
        case .viabilityChanged(_):
            //TODO: Add delegate support for viability status
            // Triggered when Network.viabilityUpdateHandler called
            /// Set a block to be called when the connection's viability changes, which may be called
            /// multiple times until the connection is cancelled.
            ///
            /// Connections that are not currently viable do not have a route, and packets will not be
            /// sent or received. There is a possibility that the connection will become viable
            /// again when network connectivity changes.
            break
        case .reconnectSuggested(_):
            //TODO: Add delegate support for reconnections
            // Triggered when Network.betterPathUpdateHandler called
            /// A better path being available indicates that the system thinks there is a preferred path or
            /// interface to use, compared to the one this connection is actively using. As an example, the
            /// connection is established over an expensive cellular interface and an unmetered Wi-Fi interface
            /// is now available.
            ///
            /// Set a block to be called when a better path becomes available or unavailable, which may be called
            /// multiple times until the connection is cancelled.
            ///
            /// When a better path is available, if it is possible to migrate work from this connection to a new connection,
            /// create a new connection to the endpoint. Continue doing work on this connection until the new connection is
            /// ready. Once ready, transition work to the new connection and cancel this one.
            break
        case .cancelled:
            break
        case .error(let error):
            print("ERROR: \(error.debugDescription)")
        }
    }
}
