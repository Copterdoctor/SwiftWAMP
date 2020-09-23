//
//  WampMessages.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

protocol WampMessage {
    init(payload: [Any])
    func marshal() -> [Any]
}

enum WampMessages: Int {

    // MARK: Basic profile messages

    case hello = 1
    case welcome = 2
    case abort = 3
    case goodbye = 6

    case error = 8

    case publish = 16
    case published = 17
    case subscribe = 32
    case subscribed = 33
    case unsubscribe = 34
    case unsubscribed = 35
    case event = 36

    case call = 48
    case result = 50
    case register = 64
    case registered = 65
    case unregister = 66
    case unregistered = 67
    case invocation = 68
    case yield = 70

    // MARK: Advance profile messages
    case challenge = 4
    case authenticate = 5

    /// payload consists of all data related to a message, WIHTHOUT the first one - the message identifier
    typealias WampMessageFactory = (_ payload: [Any]) -> WampMessage

    // Split into 2 dictionaries because Swift compiler thinks a single one is too complex
    // Perhaps find a better solution in the future

    fileprivate static let mapping1: [WampMessages: WampMessageFactory] = [
        WampMessages.error: ErrorWampMessage.init,

        // Session
        WampMessages.hello: HelloWampMessage.init,
        WampMessages.welcome: WelcomeWampMessage.init,
        WampMessages.abort: AbortWampMessage.init,
        WampMessages.goodbye: GoodbyeWampMessage.init,

        // Auth
        WampMessages.challenge: ChallengeWampMessage.init,
        WampMessages.authenticate: AuthenticateWampMessage.init,
        
        // RPC
        WampMessages.call: CallWampMessage.init,
        WampMessages.result: ResultWampMessage.init,
        WampMessages.register: RegisterWampMessage.init,
        WampMessages.registered: RegisteredWampMessage.init,
        WampMessages.invocation: InvocationWampMessage.init,
        WampMessages.yield: YieldWampMessage.init,
        WampMessages.unregister: UnregisterWampMessage.init,
        WampMessages.unregistered: UnregisteredWampMessage.init,

        // PubSub
        WampMessages.publish: PublishWampMessage.init,
        WampMessages.published: PublishedWampMessage.init,
        WampMessages.event: EventWampMessage.init,
        WampMessages.subscribe: SubscribeWampMessage.init,
        WampMessages.subscribed: SubscribedWampMessage.init,
        WampMessages.unsubscribe: UnsubscribeWampMessage.init,
        WampMessages.unsubscribed: UnsubscribedWampMessage.init
    ]

//    fileprivate static let mapping2: [WampMessages: WampMessageFactory] = [
//        // RPC
//        WampMessages.call: CallWampMessage.init,
//        WampMessages.result: ResultWampMessage.init,
//        WampMessages.register: RegisterWampMessage.init,
//        WampMessages.registered: RegisteredWampMessage.init,
//        WampMessages.invocation: InvocationWampMessage.init,
//        WampMessages.yield: YieldWampMessage.init,
//        WampMessages.unregister: UnregisterWampMessage.init,
//        WampMessages.unregistered: UnregisteredWampMessage.init,
//
//        // PubSub
//        WampMessages.publish: PublishWampMessage.init,
//        WampMessages.published: PublishedWampMessage.init,
//        WampMessages.event: EventWampMessage.init,
//        WampMessages.subscribe: SubscribeWampMessage.init,
//        WampMessages.subscribed: SubscribedWampMessage.init,
//        WampMessages.unsubscribe: UnsubscribeWampMessage.init,
//        WampMessages.unsubscribed: UnsubscribedWampMessage.init
//    ]


    static func createMessage(_ payload: [Any]) -> WampMessage? {
        if let messageType = WampMessages(rawValue: payload[0] as! Int) {
            if let messageFactory = mapping1[messageType] {
                return messageFactory(Array(payload[1..<payload.count]))
            }
        }
        return nil
    }
}
