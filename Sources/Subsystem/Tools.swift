//
//  Tools.swift
//  Subsystem
//
//  Created by Денис Либит on 19.06.2023.
//

import Foundation


extension Optional {
    func unwrap(or error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
            case .some(let v): return v
            case .none: throw error()
        }
    }
}

extension OSStatus {
    static func execute(skip: [OSStatus] = [], descriptions: [OSStatus: String] = [:], _ closure: () -> OSStatus) throws {
        let status = closure()
        
        if status == errSecSuccess {
            return
        }
        
        if skip.contains(status) {
            return
        }
        
        if let description = descriptions[status] {
            throw status.error(description: description)
        }
        
        throw status.error()
    }
    
    func error(description: String? = nil) -> Error {
        // Security errors are defined in Security/SecBase.h
        let description: String = description ?? {
            if let cfString = SecCopyErrorMessageString(self, nil) {
                return cfString as String
            } else {
                return NSLocalizedString("Ошибка с кодом \(self)", comment: "Общий текст ошибки OSStatus.")
            }
        }()

        return NSError(
            domain:   NSOSStatusErrorDomain,
            code:     Int(self),
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}
