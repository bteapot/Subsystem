//
//  Files.swift
//  Subsystem
//
//  Created by Денис Либит on 08.09.2020.
//

import Foundation


// MARK: - Files

public final class Files<Base: Subsystem> {
    required init(title: String) {
        self.title = title
    }
    
    let title: String
    
    public lazy var folderURL: URL = {
        // папка сервиса
        let url = AppSubsystem.folderURL.appendingPathComponent(self.title)
        
        // создадим, если нужно
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        // отдадим
        return url
    }()
}

// MARK: - Методы

extension Files {
    public func get(_ key: Key) -> Data? {
        return FileManager.default.contents(atPath: self.path(for: key))
    }
    
    public func load<T>(_ key: Key, make: @escaping (Data) -> T) -> T? {
        if let data = self.get(key) {
            return make(data)
        } else {
            return nil
        }
    }
    
    public func set(_ key: Key, value: Data?) throws {
        if let data = value {
            try data.write(to: self.url(for: key))
        } else {
            try self.delete(key)
        }
    }
    
    public func delete(_ key: Key) throws {
        if self.contains(key) {
            try FileManager.default.removeItem(at: self.url(for: key))
        }
    }
    
    public func contains(_ key: Key) -> Bool {
        return FileManager.default.fileExists(atPath: self.path(for: key))
    }
}

// MARK: - Ключи

extension Files {
    public struct Key {
        public init(title: String = #function) {
            self.title = title
        }
        
        let title: String
    }
}

// MARK: - Инструменты

extension Files {
    public func url(for key: Key) -> URL {
        return self.folderURL.appendingPathComponent(key.title)
    }
    
    public func path(for key: Key) -> String {
        return self.url(for: key).path
    }
    
    public func subfolder(name: String) -> URL {
        let url = self.folderURL.appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
