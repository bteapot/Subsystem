//
//  Defaults.swift
//  Subsystem
//
//  Created by Денис Либит on 25.07.2020.
//

import Foundation


// MARK: - Defaults

public struct Defaults<Base: Subsystem>: Sendable {
    public init(title: String) {
        self.title = title
    }
    
    let title: String
}

// MARK: - Регистрация

extension Defaults {
    public func register<V>(`default` key: Key<V>, _ value: V) {
        key.value.def(self.defaults(for: key.group), self.rawValue(key), value)
    }
}

// MARK: - Методы

extension Defaults {
    public func get<V>(_ key: Key<V>) -> V? {
        return key.value.get(self.defaults(for: key.group), self.rawValue(key))
    }
    
    public func set<V>(_ key: Key<V>, value: V?) {
        key.value.set(self.defaults(for: key.group), self.rawValue(key), value)
    }
    
    public func delete<V>(_ key: Key<V>) {
        self.defaults(for: key.group).removeObject(forKey: self.rawValue(key))
    }
    
    public func contains<V>(_ key: Key<V>) -> Bool {
        return self.defaults(for: key.group).object(forKey: self.rawValue(key)) != nil
    }
    
    public func rawValue<V>(_ key: Key<V>) -> String {
        return self.expand(key.title)
    }
    
    public func observe<V>(_ key: Key<V>, initial: Bool = false, receive: @escaping (V?) -> Void) -> Any {
        return Observer(self.defaults(for: key.group), self.rawValue(key), initial, receive) { key.value.get($0, $1) }
    }
}

extension Defaults {
    public func get(_ key: Key<Bool>) -> Bool {
        return self.defaults(for: key.group).bool(forKey: self.rawValue(key))
    }
    public func get(_ key: Key<Int>) -> Int {
        return self.defaults(for: key.group).integer(forKey: self.rawValue(key))
    }
    public func get(_ key: Key<Float>) -> Float {
        return self.defaults(for: key.group).float(forKey: self.rawValue(key))
    }
    public func get(_ key: Key<Double>) -> Double {
        return self.defaults(for: key.group).double(forKey: self.rawValue(key))
    }
}

extension Defaults {
    public func observe(_ key: Key<Bool>, initial: Bool = false, receive: @escaping (Bool) -> Void) -> Any {
        return Observer(self.defaults(for: key.group), self.rawValue(key), initial, receive) { $0.bool(forKey: $1) }
    }
    public func observe(_ key: Key<Int>, initial: Bool = false, receive: @escaping (Int) -> Void) -> Any {
        return Observer(self.defaults(for: key.group), self.rawValue(key), initial, receive) { $0.integer(forKey: $1) }
    }
    public func observe(_ key: Key<Float>, initial: Bool = false, receive: @escaping (Float) -> Void) -> Any {
        return Observer(self.defaults(for: key.group), self.rawValue(key), initial, receive) { $0.float(forKey: $1) }
    }
    public func observe(_ key: Key<Double>, initial: Bool = false, receive: @escaping (Double) -> Void) -> Any {
        return Observer(self.defaults(for: key.group), self.rawValue(key), initial, receive) { $0.double(forKey: $1) }
    }
}

// MARK: - Ключи

extension Defaults {
    public struct Key<V: Sendable>: Sendable {
        public init(title: String = #function, _ value: Value<V>, group: String? = nil) {
            self.title = title
            self.group = group
            self.value = value
        }
        
        let title: String
        let group: String?
        let value: Value<V>
    }
}

// MARK: - Значения

extension Defaults {
    public struct Value<V: Sendable>: Sendable {
        typealias Get = @Sendable (UserDefaults, String) -> V?
        typealias Set = @Sendable (UserDefaults, String, V?) -> Void
        
        let get: Get
        let set: Set
        let def: Set
        
        private init(get: @escaping Get, set: @escaping Set, def: @escaping Set) {
            self.get = get
            self.set = set
            self.def = def
        }
        
        public static func url() -> Value<URL> {
            Value<URL>(
                get: { $0.url(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }
        
        public static func array<E: _ObjectiveCBridgeable>() -> Value<Array<E>> {
            Value<Array<E>>(
                get: { $0.array(forKey: $1) as? Array<E> },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }
        
        public static func rawArray<E: RawRepresentable>() -> Value<Array<E>> {
            Value<Array<E>>(
                get: { ($0.array(forKey: $1) as? Array<E.RawValue>)?.compactMap({ .init(rawValue: $0) }) },
                set: { $0.set($2?.map(\.rawValue), forKey: $1) },
                def: { $0.register($2?.map(\.rawValue), forKey: $1) }
            )
        }
        
        public static func dictionary<K: _ObjectiveCBridgeable, B: _ObjectiveCBridgeable>() -> Value<Dictionary<K, B>> {
            Value<Dictionary<K, B>>(
                get: { $0.dictionary(forKey: $1) as? Dictionary<K, B> },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }
        
        public static func string() -> Value<String> {
            Value<String>(
                get: { $0.string(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }

        public static func data() -> Value<Data> {
            Value<Data>(
                get: { $0.data(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }
        
        public static func bool() -> Value<Bool> {
            Value<Bool>(
                get: { $0.bool(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }

        public static func integer() -> Value<Int> {
            Value<Int>(
                get: { $0.integer(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }

        public static func float() -> Value<Float> {
            Value<Float>(
                get: { $0.float(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }

        public static func double() -> Value<Double> {
            Value<Double>(
                get: { $0.double(forKey: $1) },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
            )
        }
        
        public static func date() -> Value<Date> {
            Value<Date>(
                get: { $0.object(forKey: $1) as? Date },
                set: { $0.set($2, forKey: $1) },
                def: { $0.register($2, forKey: $1) }
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
                set: { $0.set($2?.rawValue, forKey: $1) },
                def: { $0.register($2?.rawValue, forKey: $1) }
            )
        }
        
        public static func codable<T: Codable>() -> Value<T> {
            Value<T>(
                get: {
                    if let data = $0.data(forKey: $1) {
                        return try? JSONDecoder().decode(T.self, from: data)
                    } else {
                        return nil
                    }
                },
                set: {
                    if let value = $2 {
                        $0.set(try? JSONEncoder().encode(value), forKey: $1)
                    } else {
                        $0.set(nil, forKey: $1)
                    }
                },
                def: {
                    if let value = $2 {
                        $0.register(try? JSONEncoder().encode(value), forKey: $1)
                    }
                }
            )
        }
    }
}

// MARK: - Инструменты

private extension Defaults {
    func defaults(for group: String?) -> UserDefaults {
        if let group {
            return AppSubsystem.suitesMutex.withLock { suites in
                if let suite = suites[group] {
                    return suite
                } else {
                    let suite = UserDefaults(suiteName: group)!
                    suites[group] = suite
                    return suite
                }
            }
        } else {
            return UserDefaults.standard
        }
    }
    
    func expand(_ key: String) -> String {
        let prefix = AppSubsystem.prefix
        
        if prefix.isEmpty == false {
            return "\(prefix)-\(self.title)-\(key)"
        } else {
            return "\(self.title)-\(key)"
        }
    }
}

private extension Defaults {
    final class Observer<V>: NSObject {
        init(
            _ defaults: UserDefaults,
            _ keyPath:  String,
            _ initial:  Bool,
            _ receive:  @escaping (V) -> Void,
            _ retreive: @escaping (_ defaults: UserDefaults, _ keyPath: String) -> V
        ) {
            self.defaults = defaults
            self.keyPath = keyPath
            self.retreive = retreive
            self.receive = receive
            self.cancel = { defaults.removeObserver($0, forKeyPath: keyPath) }
            
            super.init()
            
            defaults.addObserver(self, forKeyPath: keyPath, options: initial ? [.initial, .new] : .new, context: nil)
        }
        
        deinit {
            self.cancel(self)
        }
        
        private let defaults: UserDefaults
        private let keyPath:  String
        private let receive: (V) -> Void
        private let retreive: (UserDefaults, String) -> V
        private let cancel: (Defaults.Observer<V>) -> Void
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            let value = self.retreive(self.defaults, self.keyPath)
            self.receive(value)
        }
    }
}

private extension UserDefaults {
    func register<V>(_ value: V?, forKey: String) {
        if let value {
            self.register(defaults: [forKey: value])
        }
    }
}
