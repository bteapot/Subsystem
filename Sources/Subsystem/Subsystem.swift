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
///     extension Keychain.Key where Base == SomeClass {
///         static var server:      Keychain.Key<URL>           { .init(.codable()) }
///         static var config:      Keychain.Key<ServerConfig>  { .init(.codable()) }
///         static var username:    Keychain.Key<String>        { .init(.string())  }
///         static var token:       Keychain.Key<Data>          { .init(.data())    }
///     }
///
///     extension Defaults.Key where Base == SomeClass {
///         static var selectedTab: Defaults.Key<Int>           { .init(.integer()) }
///         static var lastSearch:  Defaults.Key<String>        { .init(.string())  }
///     }
///
///     extension Files.Key where Base == SomeClass {
///         static var logo:        Files.Key                   { .init() }
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
