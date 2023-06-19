//
//  Subsystem.swift
//  Subsystem
//
//  Created by Денис Либит on 08.09.2020.
//

import Foundation


/// Подсистема
///
/// Объявлять так:
///
///     import Subsystem
///
///     extension SomeClass: Subsystem {
///         static let assets = Assets<SomeClass>()
///     }
///
/// Объявлять ключи так:
///
///     extension Keychain.Item where Base == SomeClass {
///         static var server:      Keychain.Item<URL>          { .codable() }
///         static var config:      Keychain.Item<ServerConfig> { .codable() }
///         static var username:    Keychain.Item<String>       { .string()  }
///         static var token:       Keychain.Item<Data>         { .data()    }
///     }
///
///     extension Defaults.Item where Base == SomeClass {
///         static var selectedTab: Defaults.Item<Int>          { .integer() }
///         static var lastSearch:  Defaults.Item<String>       { .string()  }
///     }
///
///     extension Files.Item where Base == SomeClass {
///         static var logo:        Files.Item                  { .init() }
///     }
///
/// Использовать так:
///
///     SomeClass.assets.keychain.set(.token, value: "uuid-1234")
///     let username = try SomeClass.assets.keychain.get(.username)
///
///     SomeClass.assets.defaults.set(.selectedTab, value: 2)
///
///     let downloadsFolderURL = SomeClass.assets.files.subfolder(name: "downloads")
///     try SomeClass.assets.files.delete(.logo)
///     try SomeClass.assets.files.set(.logo, value: data)
///
///     SomeClass.assets.log.info("поехали")
///
public protocol Subsystem {
    static var assets: Assets<Self> { get }
}
