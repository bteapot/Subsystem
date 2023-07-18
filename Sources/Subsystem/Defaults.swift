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

// MARK: - Регистрация

extension Defaults {
    public func register(defaults: [String : Any]) {
        self.defaults.register(defaults: defaults)
    }
}

// MARK: - Методы

extension Defaults {
    public func get<V>(_ key: Key<V>) -> V? {
        return key.value.get(self.defaults, self.expand(key.title))
    }
    
    public func set<V>(_ key: Key<V>, value: V?) {
        key.value.set(self.defaults, self.expand(key.title), value)
    }
    
    public func delete<V>(_ key: Key<V>) {
        self.defaults.removeObject(forKey: self.expand(key.title))
    }
    
    public func contains<V>(_ key: Key<V>) -> Bool {
        return self.defaults.object(forKey: self.expand(key.title)) != nil
    }
    
    public func rawValue<V>(_ key: Key<V>) -> String {
        return self.expand(key.title)
    }
}

// MARK: - Ключи

extension Defaults {
    public struct Key<V> {
        public init(title: String = #function, _ value: Value<V>) {
            self.title = title
            self.value = value
        }
        
        let title: String
        let value: Value<V>
    }
}

// MARK: - Значения

extension Defaults {
    public final class Value<V> {
        typealias Get = (UserDefaults, String) -> V?
        typealias Set = (UserDefaults, String, V?) -> Void
        
        let get: Get
        let set: Set
        
        private init(get: @escaping Get, set: @escaping Set) {
            self.get = get
            self.set = set
        }
        
        public static func url() -> Value<URL> {
            Value<URL>(
                get: { $0.url(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }
        
        public static func array<E>() -> Value<Array<E>> {
            Value<Array<E>>(
                get: { $0.array(forKey: $1) as? Array<E> },
                set: { $0.set($2, forKey: $1) }
            )
        }
        
        public static func dictionary<K, V>() -> Value<Dictionary<K, V>> {
            Value<Dictionary<K, V>>(
                get: { $0.dictionary(forKey: $1) as? Dictionary<K, V> },
                set: { $0.set($2, forKey: $1) }
            )
        }
        
        public static func string() -> Value<String> {
            Value<String>(
                get: { $0.string(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }

        public static func data() -> Value<Data> {
            Value<Data>(
                get: { $0.data(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }
        
        public static func bool() -> Value<Bool> {
            Value<Bool>(
                get: { $0.bool(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }

        public static func integer() -> Value<Int> {
            Value<Int>(
                get: { $0.integer(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }

        public static func float() -> Value<Float> {
            Value<Float>(
                get: { $0.float(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }

        public static func double() -> Value<Double> {
            Value<Double>(
                get: { $0.double(forKey: $1) },
                set: { $0.set($2, forKey: $1) }
            )
        }
        
        public static func date() -> Value<Date> {
            Value<Date>(
                get: { $0.object(forKey: $1) as? Date },
                set: { $0.set($2, forKey: $1) }
            )
        }
        
        public static func raw<T: RawRepresentable>() -> Value<T> {
            Value<T>(
                get: {
                    if let value = $0.object(forKey: $1) as? T.RawValue {
                        return T(rawValue: value)
                    } else {
                        return nil
                    }
                },
                set: { $0.set($2?.rawValue, forKey: $1) }
            )
        }
        
        public static func codable<T: Codable>() -> Value<T> {
            Value<T>(
                get: {
                    if let data = $0.data(forKey: $1) {
                        return try! JSONDecoder().decode(T.self, from: data)
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
