//
//  Assets.swift
//  Subsystem
//
//  Created by Денис Либит on 19.06.2023.
//

import Foundation
import OSLog


// MARK: - Активы подсистемы

public final class Assets<Base: Subsystem> {
    
    // MARK: - Инициализация
    
    public required init(
        title:    String? = nil,
        category: String? = nil
    ) {
        self.title    = title ?? String(describing: Base.self)
        self.category = category
        
        #if DEBUG
        AppSubsystem.registrar.register(self.title)
        #endif
    }
    
    // MARK: - Свойства
    
    public let title:    String
    public let category: String?
    
    // MARK: - Активы
    
    public lazy var keychain = Keychain<Base>(title: self.title)
    public lazy var defaults = Defaults<Base>(title: self.title)
    public lazy var files    = Files<Base>(title: self.title)
    public lazy var log      = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: self.category ?? self.title)
}

// MARK: - Дебаг

#if DEBUG
private extension AppSubsystem {
    static let registrar = Registrar()
}

private extension AppSubsystem {
    actor Registrar {
        private var titles: Set<String> = []
        
        private func append(_ title: String) {
            if self.titles.contains(title) {
                fatalError("Subsystem <\(title)> already registered.")
            } else {
                self.titles.insert(title)
            }
        }
        
        nonisolated func register(_ title: String) {
            Task {
                await self.append(title)
            }
        }
    }
}
#endif
