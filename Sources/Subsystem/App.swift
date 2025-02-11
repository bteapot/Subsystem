//
//  App.swift
//  Subsystem
//
//  Created by Денис Либит on 09.09.2020.
//

import Foundation


// MARK: - Приложение

public struct AppSubsystem {
    
    // MARK: - Префикс настроек
    
    public static func set(prefix: String) {
        self.prefix = prefix
    }
    
    static var prefix: String = ""
    
    static let folderURL: URL = {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appBundleID = Bundle.main.bundleIdentifier!
        
        // url папки в Application Support
        let appURL = appSupportURL.appendingPathComponent(appBundleID)
        
        // создадим, если нужно
        try! FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        
        // отдадим
        return appURL
    }()
    
    // MARK: - Релиз
    
    public static let release = Release()
    public static let dates   = Dates()
}

// MARK: - Релиз

extension AppSubsystem {
    public struct Release: Sendable {
        public let current:  Version
        public let previous: Version
        public let updated:  Bool
        public let clean:    Bool
        
        init() {
            // текущая
            let v = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0"
            let b = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "0"
            self.current = Version(rawValue: "\(v)+\(b)") ?? Version(0, 0, 0)
            
            // прошлая
            self.previous = AppSubsystem.assets.defaults.get(.version) ?? Version(0, 0, 0)
            
            // чистая установка?
            if AppSubsystem.assets.defaults.contains(.version) == false {
                self.updated = false
                self.clean   = true
            } else {
                self.updated = self.current > self.previous
                self.clean   = false
            }
        }
        
        public func save() {
            AppSubsystem.assets.defaults.set(.version, value: self.current)
        }
    }
}

// MARK: - Даты

extension AppSubsystem {
    public struct Dates {
        public let installed: Date
        public let updated:   Date
        
        init() {
            // дата установки
            if  let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.path(percentEncoded: false),
                let date = try? FileManager.default.attributesOfItem(atPath: path)[.creationDate] as? Date
            {
                self.installed = date
            } else {
                self.installed = .distantPast
            }
            
            // дата обновления
            if  let path = Bundle.main.executablePath,
                let date = try? FileManager.default.attributesOfItem(atPath: path)[.creationDate] as? Date
            {
                self.updated = date
            } else {
                self.updated = .distantPast
            }
        }
    }
}

// MARK: - Версия

extension AppSubsystem.Release {
    /// Semantic versioning
    ///
    /// https://semver.org
    public struct Version: Sendable {
        public let major: Int
        public let minor: Int
        public let patch: Int
        
        public let prereleases: [String]
        public let builds: [String]
        
        public init(_ major: Int, _ minor: Int, _ patch: Int, prereleases: [String] = [], builds: [String] = []) {
            self.major = major
            self.minor = minor
            self.patch = patch
            self.prereleases = prereleases
            self.builds = builds
        }
        
        public static func version(_ major: Int, _ minor: Int, _ patch: Int, prereleases: [String] = [], builds: [String] = []) -> Self {
            return .init(major, minor, patch, prereleases: prereleases, builds: builds)
        }
    }
}

extension AppSubsystem.Release.Version: RawRepresentable {
    public init?(rawValue: String) {
        // https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
        //
        // модифицировано для поддержки кратких версий (типа "1.2").
        let pattern =
            #"^(?<major>0|[1-9]\d*)(?:\.(?<minor>0|[1-9]\d*))?(?:\.(?<patch>0|[1-9]\d*))?(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let nsrange = NSRange(rawValue.startIndex..<rawValue.endIndex, in: rawValue)
        
        var success: Bool = false
        
        var major: Int = 0
        var minor: Int = 0
        var patch: Int = 0
        var prereleases: String = ""
        var builds: String = ""
        
        regex.enumerateMatches(in: rawValue, range: nsrange) { (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else {
                return
            }
            
            let string = { (name: String) -> String? in
                let nsrange = match.range(withName: name)
                
                if  nsrange.location != NSNotFound,
                    let range = Range(nsrange, in: rawValue)
                {
                    return String(rawValue[range])
                } else {
                    return nil
                }
            }
            
            let int = { (name: String) -> Int? in
                if  let string = string(name),
                    let int = Int(string)
                {
                    return int
                } else {
                    return nil
                }
            }
            
            guard let _major = int("major") else {
                return
            }
            
            success = true
            
            major = _major
            minor = int("minor") ?? 0
            patch = int("patch") ?? 0
            prereleases = string("prerelease") ?? ""
            builds = string("buildmetadata") ?? ""
        }
        
        if success == false {
            return nil
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleases = prereleases.split(separator: ".").map(String.init)
        self.builds = builds.split(separator: ".").map(String.init)
    }
    
    public init?(loose: String) {
        let result: [Int?] =
            loose
                .split(separator: ".")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map(Int.init)
        
        let blocks: [Int] =
            result
                .compactMap { $0 }
        
        guard
            blocks.count == result.count
        else {
            return nil
        }
        
        if blocks.count > 0 { self.major = blocks[0] } else { self.major = 0 }
        if blocks.count > 1 { self.minor = blocks[1] } else { self.minor = 0 }
        if blocks.count > 2 { self.patch = blocks[2] } else { self.patch = 0 }
        
        self.prereleases = []
        self.builds = []
    }
    
    public var rawValue: String {
        var string = "\(self.major).\(self.minor).\(self.patch)"
        
        if self.prereleases.isEmpty == false {
            string += "-" + self.prereleases.joined(separator: ".")
        }
        
        if self.builds.isEmpty == false {
            string += "+" + self.builds.joined(separator: ".")
        }
        
        return string
    }
}

extension AppSubsystem.Release.Version: Comparable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.major       != rhs.major       { return false }
        if lhs.minor       != rhs.minor       { return false }
        if lhs.patch       != rhs.patch       { return false }
        if lhs.prereleases != rhs.prereleases { return false }
        if lhs.builds      != rhs.builds      { return false }
        
        return true
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major       != rhs.major       { return lhs.major        < rhs.major }
        if lhs.minor       != rhs.minor       { return lhs.minor        < rhs.minor }
        if lhs.patch       != rhs.patch       { return lhs.patch        < rhs.patch }
        if lhs.prereleases != rhs.prereleases { return lhs.prereleases.isNumericallyLess(than: rhs.prereleases) }
        if lhs.builds      != rhs.builds      { return lhs.builds.isNumericallyLess(than: rhs.builds) }
        
        return false
    }
}

private extension String {
    func isNumericallyLess(than other: Self) -> Bool {
        if let lhi = Int(self), let rhi = Int(other) {
            return lhi < rhi
        } else {
            return self < other
        }
    }
}

private extension Array where Element == String {
    func isNumericallyLess(than other: Self) -> Bool {
        for (lhv, rhv) in zip(self, other) {
            if lhv != rhv { return lhv.isNumericallyLess(than: rhv) }
        }
        
        return self.count < other.count
    }
}

extension AppSubsystem.Release.Version {
    public var convenientValue: String {
        var string = "\(self.major).\(self.minor).\(self.patch)"
        
        if self.prereleases.isEmpty == false {
            string += "-" + self.prereleases.joined(separator: ".")
        }
        
        if self.builds.isEmpty == false {
            string += " (" + self.builds.joined(separator: ".") + ")"
        }
        
        return string
    }
}

extension AppSubsystem.Release.Version: Codable {}

// MARK: - Подсистема

extension AppSubsystem: Subsystem {
    public static let assets = Assets<Self>(title: "App")
}

extension Defaults.Key where Base == AppSubsystem {
    static var version: Defaults.Key<AppSubsystem.Release.Version> { .init(.raw()) }
}
