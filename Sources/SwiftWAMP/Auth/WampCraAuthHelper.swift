//
//  WampCraAuthHelper.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import CryptoSwift

public class WampCraAuthHelper {
    /// Helper function to create authentication in response to challenge to authenticate with router/broker
    /// - Parameters:
    ///   - secret: Shared secret between the client and broker. Refer to router documentation
    ///   - challenge: Supplied by router/broker to compute authentication
    /// - Returns: Base64 encoded authentication string that will be included in AUTHENTICATION message
    public static func sign(_ secret: String, challenge: String) -> String {
        let hmac: Array<UInt8> = try! HMAC(key: secret.utf8.map {$0}, variant: .sha256).authenticate(challenge.utf8.map {$0})
        return hmac.toBase64()!
    }
}
