# Swift WAMP

[![swift-version](https://img.shields.io/badge/swift-5.3-brightgreen.svg)](https://github.com/apple/swift)

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS%20%7C%20macOS-blue)](https://github.com/Carthage/Carthage)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

Swift wamp is a [Web Application Messaging Protocal](https://wamp-proto.org/) implementation in Swift.

It is compatable and tested using [CrossbarIO](https://crossbar.io/) router.

This package is based on [iscriptology/swamp](https://github.com/iscriptology/swamp) which is no longer being maintained or compatable with Swift 5 and Starscream 3.0.

It currently supports registering and calling remote procedures, subscribing on topics, and publishing topic events. It also supports authentication using ticket & wampcra authentication.

Swift wamp utilizes WebSockets as its only available transport, and JSON as its serialization method.

## Swift Package Manager

Too add SwiftWamp include the following package to your Package.json or add through xCode Add Package Dependencies.

```swift
// Package.json
.Package(url: "https://github.com/Copterdoctor/SwiftWAMP.git", from: "1.0.0")
```

## CARTHAGE

Too add SwiftWAMP using carthage add the following to your Cartfile.

```sh
# Cartfile
git "Copterdoctor/SwiftWAMP.git"
```

## Setup

### Connect to router without authentication

```swift
import SwiftWAMP

<!-- Conform to WampSessionDelegate protocol -->

class ViewController: WampSessionDelegate {

    var session: WampSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        let transport = WampSocket(wsEndpoint:  URL(string: <#"ws://my-router.com:8080/ws"#>)!)
        self.session = WampSession.init(realm: <#"router-defined-realm"#>, transport: transport)
        // Set WampSessionDelegate
        session.delegate = self
        session.connect()
    }

    func wampSessionConnected(_ session: WampSession, sessionId: Int) { }

    func wampSessionEnded(_ reason: String) { }

}
```

### WampSession constructor parameters

* `realm` - Which realm to join. e.g. realm1
* `transport` - A `WampSocket` implementation

### WampSessionDelegate interface

Implement the following method:

* `func wampSessionConnected(session: WampSession, sessionId: Int)`
* Fired once the session has established and authenticated a session, and has joined the realm successfully. 

Optional methods:

* `func wampSessionHandleChallenge(authMethod: String, extra: [String: Any]) -> String`
* Fired when a challenge request arrives.
* You can use `WampCraAuthHelper.sign("your-secret", extra["challenge"] as! String)` to support `wampcra` auth method.

* `func wampSessionEnded(reason: String)`
* Fired once the connection has ended.
* `reason` is usually a WAMP-domain error. e.g. "wamp.close.goodbye_and_out"

### Connect to router with wampcra authentication

Refer to router documentation for roles and shared secret.

```swift
import SwiftWAMP

<!-- Conform to WampSessionDelegate protocol -->

class ViewController: WampSessionDelegate {

    var session: WampSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        let transport = WampSocket(wsEndpoint:  URL(string: <#"ws://my-router.com:8080/ws"#>)!)
        WampSession.init(realm: <#"router-defined-realm"#>, transport: transport, authmethods: ["wampcra"], authid: <#username#>, authrole: <#role#>, authextra: nil)
        // Set WampSessionDelegate
        session.delegate = self
        session.connect()
    }

<!-- Implement wampSessionHandleChallenge if using wampcra and set secret as per router docs-->

    func wampSessionHandleChallenge(authMethod: String, challenge: [String: Any]) -> String {
        return WampCraAuthHelper.sign(<#"my_secret"#>, challenge: challenge["challenge"] as! String)
    }

    func wampSessionConnected(_ session: WampSession, sessionId: Int) { }

    func wampSessionEnded(_ reason: String) { }

}
```

* `authmethods` Is used by the client to announce the authentication methods it is prepared to perform. For WAMP-CRA, this MUST include "wampcra". Leave nil for anonymous.
* `authid` Is the authentication ID (e.g. username) the client wishes to authenticate as. For WAMP-CRA, this MUST be provided. Leave nil for anonymous.
* `authrole` The desired role inside the realm. Refer to routers documentation. Leave nil if auth not required by router like Crossbario/Crossbar docker image.
* `authextra` - Application-specific information. Refer to routers documentation. Leave nil if auth not required by router like Crossbario/Crossbar docker image.

### Connection/Disconnection

* `connect()` - Establish transport and perform authentication if configured.
* `disconnect()` - Manual Disconnect of websocket.

___

## WAMP ROUTING

**General note: Lots of callback functions receive args-kwargs pairs, check your other client implementaion to see which of them is utilized, and act accordingly.**

## RPC Calling

```swift
public func call(proc: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil, onSuccess: CallCallback, onError: ErrorCallCallback)
```

* `proc`: The URI of the procedure to be called. e.g. "com.someapp.someremoteprocedure"
* `options`: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
* `args`: List of positional call arguments (each of arbitrary type). The list may be of zero length or nil.
* `kwargs`: Dictionary of keyword call arguments (each of arbitrary type). The dictionary may be empty or nil.
* `onSuccess`: Called when successful response from procedure containing response.
* `onError`: Called if an error occurs.

```swift
// Using Callbacks
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.call(<#"com.someapp.someremoteprocedure"#>) { (details, args, kwargs) in
        print("\(details)\(args)\(kwargs)")
    } onError: { (details, error, args, kwargs) in
        // Handle errors
    }
}

// Using delegate methods
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.call(<#"com.someapp.someremoteprocedure"#>)
}

func wampCallSuccessful(details: [String: Any], results: [Any]?, kwResults: [String: Any]?) {
    print("\(details)\(args)\(kwargs)")
}

func wampCallError(details: [String: Any], error: String, args: [Any]?, kwargs: [String: Any]?) {
    // Handle errors
}
```

Example using options, args and kwargs. Refer to router docs for usage.

```swift
session.call(<#"com.someapp.someremoteprocedure"#>, options: ["some_option": true], args: [1, "argument1"], kwargs: ["arg1": 1, "arg2": "argument2"])
```

___

## RPC Register procedure

```swift
public func register(_ proc: String, options: [String: Any]=[:], onSuccess: RegisterCallback, onError: ErrorRegisterCallback, onFire: WampProcedure)
```

* `proc`: The URI of the procedure being served. e.g. "com.myapp.myprocedure"
* `options`: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
* `onSuccess`: Called when registration is successful with wamp router.
* `onError`: Called if an error occurs.
* `onFire`: Called when responding to a call for named procedure.

```swift
// Using Callbacks
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.register(<#"com.someapp.someprocedure"#>) { (registration) in
        print("\(registration)")
    } onError: { (details, error) in
        // Handle error
    } onFire: { (details, args, kwargs) -> (options: [String : Any], args: [Any], kwargs: [String : Any]) in
        // Data being returned when procedure is called successfully
        return (<#[String : Any]#>, <#[Any]#>, <#[String : Any]#>)
    }
}


// Using delegate methods
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.register(<#"com.someapp.someprocedure"#>)
}

func wampProcedureCalled(details: [String : Any], args: [Any]?, kwargs: [String : Any]?) -> (options: [String : Any], args: [Any], kwargs: [String : Any])? {
    return (<#[String : Any]#>, <#[Any]#>, <#[String : Any]#>)
}

func wampRegistrationSuccessful(_ registration: Registration) {
    print("\(registration)")
}

func wampRegistrationError(details: [String : Any], error: String) {
    // Handle error
}


```

___

## Subscribing on topics

```swift
public func subscribe(topic: String, options: [String: AnyObject]=[:], onSuccess: SubscribeCallback, onError: ErrorSubscribeCallback, onEvent: EventCallback)
```

* `topic`: The URI of the topic to subscribe to. e.g. "com.someapp.publishedprocedure"
* `options`: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
* `onSuccess`: Called when subscription is successful with wamp router.
* `onError`: Called if an error occurs.
* `onEvent`: Called when procedure event is received.

```swift
// Using Callbacks
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.subscribe(<#"com.someapp.sometopic"#>) { (sub) in
        // Success
    } onError: { (details, error) in
        // Handle error
    } onEvent: { (details, results, kwargs) in
        print("\(details)\(args)\(kwargs)")
    }
}

// Using delegate methods
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.subscribe(<#"com.someapp.sometopic"#>)
}

func wampSubSuccessful(_ subscription: Subscription) {
    // Success
}

func wampSubError(details: [String : Any], error: String) {
    // Handle error
}

func wampSubEventReceived(details: [String : Any], results: [Any]?, kwargs: [String : Any]?) {
    print("\(details)\(args)\(kwargs)")
}
```

___

## Publishing topic events

```swift
// without acknowledging
public func publish(topic: String, options: [String: AnyObject]=[:], args: [AnyObject]?=nil, kwargs: [String: AnyObject]?=nil)
// with acknowledging
public func publish(topic: String, options: [String: AnyObject]=[:], args: [AnyObject]?=nil, kwargs: [String: AnyObject]?=nil, onSuccess: PublishCallback, onError: ErrorPublishCallback) {
```

* `topic`: The URI of the topic being published e.g. "com.myapp.mytopic
* `options`: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
* `args`: List of positional call arguments (each of arbitrary type). The list may be of zero length or nil.
* `kwargs`: Dictionary of keyword call arguments (each of arbitrary type). The dictionary may be empty or nil.
* `onSuccess`: Called when router confirms successful publish.
* `onError`: Called if an error occurs.

```swift
// Using Callbacks
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.publish(<#"com.myapp.sometopic"#>, options: [:], args: ["Hello World"], kwargs: nil, onSuccess: {
        // Success
    }, onError: { (details, error) in
        // Handle error
    })
}
// Using delegate methods
func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.publish(<#"com.myapp.sometopic"#>, options: [:], args: ["Hello World"], kwargs: nil)
}

func wampPubSuccessful() {
    // Success
}

func wampPubError(details: [String : Any], error: String) {
    // handle error
}
```

___

## Handle network connections

```swift
// Handle connection viability
connection.viabilityUpdateHandler = { (isViable) in
    if (!isViable) {
        // Handle connection temporarily losing connectivity
    } else {
        // Handle connection return to connectivity
    }
}

// Handle better paths
connection.betterPathUpdateHandler = { (betterPathAvailable) in
    if (betterPathAvailable) {
        // Start a new connection if migration is possible
    } else {
        // Stop any attempts to migrate
    }
}
```

___

## Testing

For now, only integration tests against crossbar exist.

In order to run the tests:

1. Install [Docker for Mac](https://docs.docker.com/engine/installation/mac/)
2. Pull docker image for crossbar `docker pull crossbario/crossbar`
3. Run tests from xcode. Docker container should load using start_crossbar.sh script at pre_start phase of tests and then shutdown after testing.
4. Tests should use config.json from SwiftWAMP/.crossbar. Modify this if you want to run tests using your own realm settings.

## Troubleshooting

If for some reason the tests fail, make sure:

* You have docker installed and available in PATH
* You have an available port 8080 on your machine

You can also inspect `**************/wamp-crossbar-instance.log` to find out what happened with the crossbar instance while the tests were executing.
