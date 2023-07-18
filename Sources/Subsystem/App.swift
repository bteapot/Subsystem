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
}

// MARK: - Релиз

extension AppSubsystem {
    public struct Release {
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

// MARK: - Версия

extension AppSubsystem.Release {
    /// Semantic versioning
    ///
    /// https://semver.org
    public struct Version {
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
        let blocks =
            loose
                .split(separator: ".")
                .map { block in
                    block.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                }
                .map(Int.init)
        
        if blocks.count > 0, let v = blocks[0] { self.major = v } else { self.major = 0 }
        if blocks.count > 1, let v = blocks[1] { self.minor = v } else { self.minor = 0 }
        if blocks.count > 2, let v = blocks[2] { self.patch = v } else { self.patch = 0 }
        
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
        if lhs.major != rhs.major { return false }
        if lhs.minor != rhs.minor { return false }
        if lhs.patch != rhs.patch { return false }
        
        if lhs.prereleases.count != rhs.prereleases.count { return false }
        if zip(lhs.prereleases, rhs.prereleases).contains(where: { $0 != $1 }) { return false }
        
        if lhs.builds.count != rhs.builds.count { return false }
        if zip(lhs.builds, rhs.builds).contains(where: { $0 != $1 }) { return false }
        
        return true
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major < rhs.major { return true }
        if lhs.minor < rhs.minor { return true }
        if lhs.patch < rhs.patch { return true }
        
        let numericCompare = { (lhs: String, rhs: String) -> Bool in
            if let lhsInt = Int(lhs), let rhsInt = Int(rhs) {
                return lhsInt < rhsInt
            } else {
                return lhs < rhs
            }
        }
        
        if zip(lhs.prereleases, rhs.prereleases).contains(where: numericCompare) { return true }
        if lhs.prereleases.count != rhs.prereleases.count { return lhs.prereleases.count < rhs.prereleases.count }
        
        if zip(lhs.builds, rhs.builds).contains(where: numericCompare) { return true }
        if lhs.builds.count != rhs.builds.count { return lhs.builds.count < rhs.builds.count }
        
        return false
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
