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
        if let data = try self.get(for: key.id) {
            return try key.value.get(data)
        } else {
            return nil
        }
    }
    
    public func set<V>(_ key: Key<V>, value: V) throws {
        try self.set(try key.value.set(value), for: key.id)
    }
    
    public func delete<V>(_ key: Key<V>) throws {
        try self.delete(for: key.id)
    }
    
    public func contains<V>(_ key: Key<V>) throws -> Bool {
        try self.contains(for: key.id)
    }
    
    public func rawValue<V>(_ key: Key<V>) -> String {
        return self.expand(key.id.title)
    }
}

// MARK: - Ключи

extension Keychain {
    public struct Key<V> {
        public init(title: String = #function, _ value: Value<V>, group: String? = nil, sync: Bool = false, access: CFString = AppSubsystem.access) {
            self.id = ID(title: title, group: group, sync: sync, access: access)
            self.value = value
        }
        
        let id: ID
        let value: Value<V>
    }
}

extension Keychain {
    public struct ID {
        let title: String
        let group: String?
        let sync: Bool
        let access: CFString
    }
}

// MARK: - Значения

extension Keychain {
    public struct Value<V> {
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

// MARK: - Приватное

private extension Keychain {
    func get(for id: ID) throws -> Data? {
        let query = self.dict(from: [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrService:        self.expand(id.title),
            kSecAttrAccessGroup:    id.group,
            kSecAttrSynchronizable: self.sync(for: id.sync),
            kSecMatchLimit:         kSecMatchLimitOne,
            kSecReturnData:         true,
        ])
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        
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
    
    func set(_ data: Data, for id: ID) throws {
        #if DEBUG
        if id.sync == true {
            switch id.access {
                case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                     kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                     kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
                    assertionFailure()
                    
                default:
                    break
            }
        }
        #endif
        
        let add = self.dict(from: [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrService:        self.expand(id.title),
            kSecAttrAccessGroup:    id.group,
            kSecAttrSynchronizable: self.sync(for: id.sync),
            kSecAttrAccessible:     id.access,
            kSecValueData:          data,
        ])
        
        let status = SecItemAdd(add, nil)
        
        switch status {
            case errSecSuccess:
                break
                
            case errSecDuplicateItem:
                let query = self.dict(from: [
                    kSecClass:              kSecClassGenericPassword,
                    kSecAttrService:        self.expand(id.title),
                    kSecAttrAccessGroup:    id.group,
                    kSecAttrSynchronizable: self.sync(for: id.sync),
                ])
                
                let update = self.dict(from: [
                    kSecAttrAccessible:     id.access,
                    kSecValueData:          data,
                ])
                
                try OSStatus.execute {
                    SecItemUpdate(query, update)
                }
                
            default:
                throw status.error()
        }
    }
    
    func delete(for id: ID) throws {
        let query = self.dict(from: [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrService:        self.expand(id.title),
            kSecAttrAccessGroup:    id.group,
            kSecAttrSynchronizable: self.sync(for: id.sync),
        ])
        
        try OSStatus.execute(skip: [errSecItemNotFound]) {
            SecItemDelete(query)
        }
    }
    
    func contains(for id: ID) throws -> Bool {
        let query = self.dict(from: [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrService:        self.expand(id.title),
            kSecAttrAccessGroup:    id.group,
            kSecAttrSynchronizable: self.sync(for: id.sync),
            kSecMatchLimit:         kSecMatchLimitOne,
        ])
        
        let status = SecItemCopyMatching(query, nil)
        
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

// MARK: - Инструменты

private extension Keychain {
    func expand(_ key: String) -> String {
        let prefix = AppSubsystem.prefix
        
        if prefix.isEmpty == false {
            return "\(prefix)-\(self.title)-\(key)"
        } else {
            return "\(self.title)-\(key)"
        }
    }
    
    func dict(from source: [CFString: Any?]) -> CFDictionary {
        var reduced: [String: Any] =
            source.reduce(into: [:]) { result, item in
                if let value = item.value {
                    result[item.key as String] = value
                }
            }
        
        reduced[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        
        return reduced as CFDictionary
    }
    
    func sync(for sync: Bool) -> Any {
        return sync ? kCFBooleanTrue as Any : kCFBooleanFalse as Any
    }
    
}
