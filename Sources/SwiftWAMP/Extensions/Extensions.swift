//
//  Extensions.swift
//  
//
//  Created by Jordan Anders on 2020-09-22.
//

import Foundation

// from http://stackoverflow.com/a/30593673/4017443
extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return index >= startIndex && index < endIndex ? self[index] : nil
    }
}
