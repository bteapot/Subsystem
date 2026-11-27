//
//  Tools.swift
//  Subsystem
//
//  Created by Денис Либит on 19.06.2023.
//

import Foundation


extension Optional {
    func unwrap(or error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
            case .some(let v): return v
            case .none: throw error()
        }
    }
}

extension OSStatus {
    static func execute(skip: [OSStatus] = [], descriptions: [OSStatus: String] = [:], _ closure: () -> OSStatus) throws {
        let status = closure()
        
        if status == errSecSuccess {
            return
        }
        
        if skip.contains(status) {
            return
        }
        
        if let description = descriptions[status] {
            throw status.error(description: description)
        }
        
        throw status.error()
    }
    
    func error(description: String? = nil) -> Error {
        // Security errors are defined in Security/SecBase.h
        let description: String = description ?? {
            if let cfString = SecCopyErrorMessageString(self, nil) {
                return cfString as String
            } else {
                return NSLocalizedString("Ошибка с кодом \(self)", comment: "Общий текст ошибки OSStatus.")
            }
        }()

        return NSError(
            domain:   NSOSStatusErrorDomain,
            code:     Int(self),
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}

final class Mutex<Value: ~Copyable>: @unchecked Sendable {
    
    init(_ value: consuming sending Value) {
        self.storage = Storage(value)
    }
    
    func withLock<Result: ~Copyable, E: Error>(_ body: (inout sending Value) throws(E) -> sending Result) throws(E) -> sending Result {
        self.lock.lock()
        defer { self.lock.unlock() }
        return try body(&self.storage.value)
    }
    
    private final class Storage {
        init(_ value: consuming sending Value) {
            self.value = value
        }
        
        var value: Value
    }
    
    private let storage: Storage
    private let lock = NSLock()
}

extension Mutex where Value: Sendable {
    var value: Value {
        get { self.lock.withLock { self.storage.value } }
        set { self.lock.withLock { self.storage.value = newValue } }
    }
}
