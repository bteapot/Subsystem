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
    public func get(_ item: Item) -> Data? {
        return FileManager.default.contents(atPath: self.path(for: item))
    }
    
    public func load<T>(_ item: Item, make: @escaping (Data) -> T) -> T? {
        if let data = self.get(item) {
            return make(data)
        } else {
            return nil
        }
    }
    
    public func set(_ item: Item, value: Data?) throws {
        if let data = value {
            try data.write(to: self.url(for: item))
        } else {
            try self.delete(item)
        }
    }
    
    public func delete(_ item: Item) throws {
        if self.contains(item) {
            try FileManager.default.removeItem(at: self.url(for: item))
        }
    }
    
    public func contains(_ item: Item) -> Bool {
        return FileManager.default.fileExists(atPath: self.path(for: item))
    }
}

// MARK: - Элементы

extension Files {
    public struct Item {
        public init(key: String = #function) {
            self.key = key
        }
        
        let key: String
    }
}

// MARK: - Инструменты

extension Files {
    public func url(for item: Item) -> URL {
        return self.folderURL.appendingPathComponent(item.key)
    }
    
    public func path(for item: Item) -> String {
        return self.url(for: item).path
    }
    
    public func subfolder(name: String) -> URL {
        let url = self.folderURL.appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
