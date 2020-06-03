//
//  Util.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/6/2.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    func md5() -> String {
        let data = Data(utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}

func assertNotMainThread() {
    assert(Thread.current != Thread.main)
}

func assertMainThread() {
    assert(Thread.current == Thread.main)
}

final class Atomic<A> {
    private let queue = DispatchQueue(label: "Atomic serial queue")
    private var _value: A
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        get {
            return queue.sync { self._value }
        }
    }
    
    func mutate(_ transform: (inout A) -> ()) {
        queue.sync {
            transform(&self._value)
        }
    }
}
