# Subsystem

Подсистема приложения.

## Объявлять так:

```swift
import Subsystem

extension SomeClass: Subsystem {
    static let assets = Assets<SomeClass>()
}
```

## Объявлять ключи так:

```swift
extension Keychain.Item where Base == SomeClass {
    static var server:      Keychain.Item<URL>          { .codable() }
    static var config:      Keychain.Item<ServerConfig> { .codable() }
    static var username:    Keychain.Item<String>       { .string()  }
    static var token:       Keychain.Item<Data>         { .data()    }
}

extension Defaults.Item where Base == SomeClass {
    static var selectedTab: Defaults.Item<Int>          { .integer() }
    static var lastSearch:  Defaults.Item<String>       { .string()  }
}

extension Files.Item where Base == SomeClass {
    static var logo:        Files.Item                  { .init() }
}
```

## Использовать так:

```swift
SomeClass.assets.keychain.set(.token, value: "uuid-1234")
let username = try SomeClass.assets.keychain.get(.username)

SomeClass.assets.defaults.set(.selectedTab, value: 2)

let downloadsFolderURL = SomeClass.assets.files.subfolder(name: "downloads")
try SomeClass.assets.files.delete(.logo)
try SomeClass.assets.files.set(.logo, value: data)

SomeClass.assets.log.info("поехали")
```
