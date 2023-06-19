//
//  Keychain.swift
//  Subsystem
//
//  Created by Денис Либит on 17.08.2020.
//

import Foundation


// MARK: - Keychain

public final class Keychain<Base: Subsystem> {
    init(title: String) {
        self.title = title
    }
    
    let title: String
}

// MARK: - Методы

extension Keychain {
    public func get<V>(_ item: Item<V>) throws -> V? {
        if let data = try self.get(for: item.key) {
            return try item.get(data)
        } else {
            return nil
        }
    }
    
    public func set<V>(_ item: Item<V>, value: V) throws {
        try self.set(try item.set(value), for: item.key)
    }
    
    public func delete<V>(_ item: Item<V>) throws {
        try self.delete(for: item.key)
    }
    
    public func contains<V>(_ item: Item<V>) throws -> Bool {
        try self.contains(for: item.key)
    }
    
    public func rawValue<V>(_ item: Item<V>) -> String {
        return self.expand(item.key)
    }
}

// MARK: - Элементы

extension Keychain {
    public struct Item<V> {
        typealias Get = (Data) throws -> V
        typealias Set = (V) throws -> Data
        
        let key: String
        let get: Get
        let set: Set
    }
}

extension Keychain.Item {
    public static func data(key: String = #function) -> Self where V == Data {
        .init(
            key: key,
            get: { $0 },
            set: { $0 }
        )
    }
    
    public static func string(key: String = #function) -> Self where V == String {
        .init(
            key: key,
            get: { try String(data: $0, encoding: .utf8).unwrap(or: errSecUnsupportedFormat.error()) },
            set: { try $0.data(using: .utf8).unwrap(or: errSecUnknownFormat.error()) }
        )
    }

    public static func codable(key: String = #function) -> Self where V: Codable {
        .init(
            key: key,
            get: { try JSONDecoder().decode(V.self, from: $0) },
            set: { try JSONEncoder().encode($0) }
        )
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
        let status = SecItemCopyMatching([
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: self.expand(title),
            kSecMatchLimit as String:  kSecMatchLimitOne,
            kSecReturnData as String:  true,
        ] as [String : Any] as CFDictionary, &item)
        
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
    
    func set(_ data: Data, for title: String) throws {
        if try self.contains(for: title) == true {
            try OSStatus.execute {
                SecItemUpdate([
                    kSecClass as String:       kSecClassGenericPassword,
                    kSecAttrService as String: self.expand(title),
                ] as [String : Any] as CFDictionary, [
                    kSecValueData as String:   data,
                ] as [String : Any] as CFDictionary)
            }
        } else {
            try OSStatus.execute {
                SecItemAdd([
                    kSecClass as String:       kSecClassGenericPassword,
                    kSecAttrService as String: self.expand(title),
                    kSecValueData as String:   data,
                ] as [String : Any] as CFDictionary, nil)
            }
        }
    }
    
    func delete(for title: String) throws {
        try OSStatus.execute(skip: [errSecItemNotFound]) {
            SecItemDelete([
                kSecClass as String:       kSecClassGenericPassword,
                kSecAttrService as String: self.expand(title),
            ] as [String : Any] as CFDictionary)
        }
    }
    
    func contains(for title: String) throws -> Bool {
        let status = SecItemCopyMatching([
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: self.expand(title),
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ] as [String : Any] as CFDictionary, nil)
        
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
