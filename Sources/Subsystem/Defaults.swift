//
//  Defaults.swift
//  Subsystem
//
//  Created by Денис Либит on 25.07.2020.
//

import Foundation


// MARK: - Defaults

public final class Defaults<Base: Subsystem> {
    public init?(suiteName: String, title: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }
        self.title = title
        self.defaults = defaults
    }
    
    init(title: String) {
        self.title = title
        self.defaults = UserDefaults.standard
    }
    
    let title: String
    let defaults: UserDefaults
}

// MARK: - Методы

extension Defaults {
    public func get<V>(_ item: Item<V>) -> V? {
        return item.get(self.defaults, self.expand(item.key))
    }
    
    public func set<V>(_ item: Item<V>, value: V?) {
        item.set(self.defaults, self.expand(item.key), value)
    }
    
    public func delete<V>(_ item: Item<V>) {
        self.defaults.removeObject(forKey: self.expand(item.key))
    }
    
    public func contains<V>(_ item: Item<V>) -> Bool {
        return self.defaults.object(forKey: self.expand(item.key)) != nil
    }
    
    public func rawValue<V>(_ item: Item<V>) -> String {
        return self.expand(item.key)
    }
}

// MARK: - Элементы

extension Defaults {
    public struct Item<V> {
        typealias Get = (UserDefaults, String) -> V?
        typealias Set = (UserDefaults, String, V?) -> Void
        
        let key: String
        let get: Get
        let set: Set
    }
}

extension Defaults.Item {
    public static func url(key: String = #function) -> Self where V == URL {
        .init(
            key: key,
            get: { $0.url(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }
    
    public static func array<E>(key: String = #function) -> Self where V == Array<E> {
        .init(
            key: key,
            get: { $0.array(forKey: $1) as? Array<E> },
            set: { $0.set($2, forKey: $1) }
        )
    }
    
    public static func dictionary<VK, VV>(key: String = #function) -> Self where V == Dictionary<VK, VV> {
        .init(
            key: key,
            get: { $0.dictionary(forKey: $1) as? Dictionary<VK, VV> },
            set: { $0.set($2, forKey: $1) }
        )
    }
    
    public static func string(key: String = #function) -> Self where V == String {
        .init(
            key: key,
            get: { $0.string(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }

    public static func data(key: String = #function) -> Self where V == Data {
        .init(
            key: key,
            get: { $0.data(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }
    
    public static func bool(key: String = #function) -> Self where V == Bool {
        .init(
            key: key,
            get: { $0.bool(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }

    public static func integer(key: String = #function) -> Self where V == Int {
        .init(
            key: key,
            get: { $0.integer(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }

    public static func float(key: String = #function) -> Self where V == Float {
        .init(
            key: key,
            get: { $0.float(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }

    public static func double(key: String = #function) -> Self where V == Double {
        .init(
            key: key,
            get: { $0.double(forKey: $1) },
            set: { $0.set($2, forKey: $1) }
        )
    }
    
    public static func date(key: String = #function) -> Self where V == Date {
        .init(
            key: key,
            get: { $0.object(forKey: $1) as? Date },
            set: { $0.set($2, forKey: $1) }
        )
    }
    
    public static func raw(key: String = #function) -> Self where V: RawRepresentable {
        .init(
            key: key,
            get: {
                if let value = $0.object(forKey: $1) as? V.RawValue {
                    return V(rawValue: value)
                } else {
                    return nil
                }
            },
            set: { $0.set($2?.rawValue, forKey: $1) }
        )
    }
    
    public static func codable(key: String = #function) -> Self where V: Codable {
        .init(
            key: key,
            get: {
                if let data = $0.data(forKey: $1) {
                    return try! JSONDecoder().decode(V.self, from: data)
                } else {
                    return nil
                }
            },
            set: {
                if let value = $2 {
                    $0.set(try! JSONEncoder().encode(value), forKey: $1)
                } else {
                    $0.set(nil, forKey: $1)
                }
            }
        )
    }
}

// MARK: - Инструменты

private extension Defaults {
    func expand(_ key: String) -> String {
        if AppSubsystem.prefix.isEmpty == false {
            return "\(AppSubsystem.prefix)-\(self.title)-\(key)"
        } else {
            return "\(self.title)-\(key)"
        }
    }
}
