//
//  WampCraAuthHelper.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import CryptoSwift

public class WampCraAuthHelper {
    public static func sign(_ secret: String, challenge: String) -> String {
        let hmac: Array<UInt8> = try! CryptoSwift.HMAC(key: secret.utf8.map {$0}, variant: .sha256).authenticate(challenge.utf8.map {$0})
        return hmac.toBase64()!
    }
}
