<p align="center">
  <img src="http://img.shields.io/badge/platform-iOS | tvOS | macOS-blue.svg?style=flat" alt="Platform" />
  <a href="https://developer.apple.com/swift">
    <img src="http://img.shields.io/badge/Swift-5.0-brightgreen.svg?style=flat" alt="Language">
  </a>
  <!-- <a href="https://github.com/Carthage/Carthage">
    <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage" />
  </a> -->
  <br />
  <a href="https://github.com/apple/swift-package-manager">
    <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
  </a>
</p>

# Swift WAMP

Swift wamp is a [Web Application Messaging Protocal](https://wamp-proto.org/) implementation in Swift.

It is compatable and tested using [CrossbarIO](https://crossbar.io/) router.

This package is based on [iscriptology/swamp](https://github.com/iscriptology/swamp) which is no longer being maintained or compatable with Swift 5.

It currently supports calling remote procedures, subscribing on topics, and publishing events. It also supports authentication using ticket & wampcra authentication.

Swift wamp utilizes WebSockets as its only available transport, and JSON as its serialization method.

## Swift Package Manager

Too add SwiftWamp include the following package to your Package.json or add through xCode Add Package Dependencies

```swift
// Package.json
.Package(url: "https://github.com/Copterdoctor/SwiftWAMP.git", from: "1.0.0")
```

## Setup

### Connect to router

```swift
import SwiftWAMP



let transport = WampSocket(wsEndpoint:  URL(string: <#"ws://my-router.com:8080/ws"#>)!)
let session = WampSession(realm: <#"router-defined-realm"#>, transport: transport)
// Set WampSessionDelegate
session.delegate = self
ession.connect()

<!-- Once a connection has been established wait for WampSessionDelegate's callbacks to start a WAMP Session. -->

func wampSessionConnected(_ session: WampSession, sessionId: Int) {
    session.subscribe(<#"com.myapp.hello"#>, onSuccess: { (sub) in
        print("SUBSCRIPTION: \(sub)")
    }, onError: { (details, error) in
        print("SUB ERROR DETAILS: \(details) :: ERROR: \(error)")
    }, onEvent: { (details, results, kwResults) in
        print("ON EVENT DETAILS: \(details)\n :: Results: \(results?.debugDescription)\n :: kwResults: (kwResults?.debugDescription)")
    });
}
```

### WampSession constructor parameters

* `realm` - which realm to join
* `transport` - a `WampSocket` implementation
* `authmethods` `authid` `authrole` `authextra` - See your router's documentation and use accordingly

### Connection/Disconnection

* `connect()` - Establish transport and perform authentication if configured.
* `disconnect()` - Manual Disconnect of websocket.

### WampSessionDelegate interface

Implement the following method:

* `func wampSessionConnected(session: WampSession, sessionId: Int)`
* Fired once the session has established and authenticated a session, and has joined the realm successfully. (AKA You may now call, subscribe & publish.)

Optional methods:

* `func wampSessionHandleChallenge(authMethod: String, extra: [String: AnyObject]) -> String`
* Fired when a challenge request arrives.
* You can `return WampCraAuthHelper.sign("your-secret", extra["challenge"] as! String)` to support `wampcra` auth method.

* `func wampSessionEnded(reason: String)`
* Fired once the connection has ended.
* `reason` is usually a WAMP-domain error.

# WAMP ROUTING

**General note: Lots of callback functions receive args-kwargs pairs, check your other client implementaion to see which of them is utilized, and act accordingly.**

## RPC

```swift
public func call(proc: String, options: [String: AnyObject]=[:], args: [AnyObject]?=nil, kwargs: [String: AnyObject]?=nil, onSuccess: CallCallback, onError: ErrorCallCallback)
```

* `onSuccess` - if calling has completed without errors.
* `onError` - If the call has failed. (Either in router or in peer client.)

Basic

```swift
session.call(<#"com.myapp.helloRPC"#>, args: [1, "argument1"],
    onSuccess: { details, results, kwResults in
        // Usually result is in results[0], but do a manual check in your infrastructure
    },
    onError: { details, error, args, kwargs in
        // Handle your error here (You can ignore args kwargs in most cases)
    })
```

With kwargs

```swift
session.call(<#"com.myapp.helloRPC"#>, options: ["disclose_me": true], args: [1, "argument1"], kwargs: ["arg1": 1, "arg2": "argument2"],
    onSuccess: { details, results, kwResults in
        // Usually result is in results[0], but do a manual check in your infrastructure
    },
    onError: { details, error, args, kwargs in
        // Handle your error here (You can ignore args kwargs in most cases)
    })
```

___

## Subscribing on topics

```swift
public func subscribe(topic: String, options: [String: AnyObject]=[:], onSuccess: SubscribeCallback, onError: ErrorSubscribeCallback, onEvent: EventCallback)
```

* `onSuccess` - if subscription has succeeded.
* `onError` - if subscription has failed.
* `onEvent` - if it succeeded, this is fired when the actual event was published.

Basic

```swift
session.subscribe(<#"com.myapp.hello"#>, onSuccess: { subscription in
        // subscription can be stored for subscription.cancel()
    }, onError: { details, error in
        // Handle error
    }, onEvent: { details, results, kwResults in
        // Event data is usually in results, but manually check blabla yadayada
    })
```

With kwargs

```swift
session.subscribe(<#"com.myapp.hello"#>, options: ["disclose_me": true],
    onSuccess: { subscription in
        // subscription can be stored for subscription.cancel()
    }, onError: { details, error in
        // handle error
    }, onEvent: { details, results, kwResults in
        // Event data is usually in results, but manually check blabla yadayada
    })
```

___

## Publishing events

```swift
// without acknowledging
public func publish(topic: String, options: [String: AnyObject]=[:], args: [AnyObject]?=nil, kwargs: [String: AnyObject]?=nil)
// with acknowledging
public func publish(topic: String, options: [String: AnyObject]=[:], args: [AnyObject]?=nil, kwargs: [String: AnyObject]?=nil, onSuccess: PublishCallback, onError: ErrorPublishCallback) {
```

* `onSuccess` - if publishing has succeeded to register.
* `onError` - if publishing has failed to register.

Simple

```swift
session.publish(<#"com.myapp.hello"#>, args: [1, "argument2"])
```

With options and kwargs

```swift
session.publish(<#"com.myapp.hello"#>, options: ["disclose_me": true],  args: [1, "argument2"], kwargs: ["arg1": 1, "arg2": "argument2"],
    onSuccess: {
        // Publication has been published!
    }, onError: { details, error in
        // Handle error (What can it be except wamp.error.not_authorized?)
    })
```

___

# Testing

For now, only integration tests against crossbar exist.

In order to run the tests:

1. Install [Docker for Mac](https://docs.docker.com/engine/installation/mac/) (Easy Peasy)
2. 

## Troubleshooting

If for some reason the tests fail, make sure:

* You have docker installed and available at `/usr/local/bin/docker`
* You have an available port 8080 on your machine

You can also inspect `**************/wamp-crossbar-instance.log` to find out what happened with the crossbar instance while the tests were executing.