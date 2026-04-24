//
//  Keychain.swift
//  Subsystem
//
//  Created by Денис Либит on 17.08.2020.
//

import Foundation


// MARK: - Keychain

public final class Keychain<Base: Subsystem>: Sendable {
    init(title: String) {
        self.title = title
    }
    
    let title: String
}

// MARK: - Методы

extension Keychain {
    public func get<V>(_ key: Key<V>) throws -> V? {
        if let data = try self.get(for: key.title) {
            return try key.value.get(data)
        } else {
            return nil
        }
    }
    
    public func set<V>(_ key: Key<V>, value: V) throws {
        try self.set(try key.value.set(value), for: key.title, accessible: key.accessible)
    }
    
    public func delete<V>(_ key: Key<V>) throws {
        try self.delete(for: key.title)
    }
    
    public func contains<V>(_ key: Key<V>) throws -> Bool {
        try self.contains(for: key.title)
    }
    
    public func rawValue<V>(_ key: Key<V>) -> String {
        return self.expand(key.title)
    }
}

// MARK: - Ключи

extension Keychain {
    public struct Key<V> {
        public init(title: String = #function, _ value: Value<V>, accessible: CFString = kSecAttrAccessibleWhenUnlocked) {
            self.title = title
            self.value = value
            self.accessible = accessible
        }
        
        let title: String
        let value: Value<V>
        let accessible: CFString
    }
}

// MARK: - Значения

extension Keychain {
    public final class Value<V> {
        typealias Get = (Data) throws -> V
        typealias Set = (V) throws -> Data
        
        let get: Get
        let set: Set
        
        private init(get: @escaping Get, set: @escaping Set) {
            self.get = get
            self.set = set
        }
        
        public static func data() -> Value<Data> {
            Value<Data>(
                get: { $0 },
                set: { $0 }
            )
        }
        
        public static func string() -> Value<String> {
            Value<String>(
                get: { try String(data: $0, encoding: .utf8).unwrap(or: errSecUnsupportedFormat.error()) },
                set: { try $0.data(using: .utf8).unwrap(or: errSecUnknownFormat.error()) }
            )
        }

        public static func codable<T: Codable>() -> Value<T> {
            Value<T>(
                get: { try JSONDecoder().decode(T.self, from: $0) },
                set: { try JSONEncoder().encode($0) }
            )
        }
    }
}

// MARK: - Инструменты

private extension Keychain {
    func expand(_ key: String) -> String {
        if AppSubsystem.prefix.isEmpty == false {
            return "\(AppSubsystem.prefix)-\(self.title)-\(key)"
        } else {
            return "\(self.title)-\(key)"
        }
    }
    
    func get(for title: String) throws -> Data? {
        var item: CFTypeRef?
        
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: self.expand(title),
            kSecMatchLimit as String:  kSecMatchLimitOne,
            kSecReturnData as String:  true,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        switch status {
            case errSecSuccess:
                break
                
            case errSecItemNotFound:
                return nil
                
            default:
                throw status.error()
        }
        
        if let data = item as? Data {
            return data
        } else {
            throw errSecUnknownFormat.error()
        }
    }
    
    func set(_ data: Data, for title: String, accessible: CFString) throws {
        if try self.contains(for: title) == true {
            let query: [String: Any] = [
                kSecClass as String:       kSecClassGenericPassword,
                kSecAttrService as String: self.expand(title),
            ]
            
            let update: [String: Any] = [
                kSecValueData as String:      data,
                kSecAttrAccessible as String: accessible,
            ]
            
            try OSStatus.execute {
                SecItemUpdate(query as CFDictionary, update as CFDictionary)
            }
        } else {
            let attributes: [String: Any] = [
                kSecClass as String:          kSecClassGenericPassword,
                kSecAttrService as String:    self.expand(title),
                kSecValueData as String:      data,
                kSecAttrAccessible as String: accessible,
            ]
            
            try OSStatus.execute {
                SecItemAdd(attributes as CFDictionary, nil)
            }
        }
    }
    
    func delete(for title: String) throws {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: self.expand(title),
        ]
        
        try OSStatus.execute(skip: [errSecItemNotFound]) {
            SecItemDelete(query as CFDictionary)
        }
    }
    
    func contains(for title: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: self.expand(title),
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
            case errSecSuccess:
                return true
            case errSecItemNotFound:
                return false
            default:
                throw status.error()
        }
    }
}
