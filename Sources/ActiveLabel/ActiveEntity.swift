//
//  ActiveEntity.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-11.
//

import Foundation

public class ActiveEntity {
    public var range: NSRange
    public let type: ActiveEntityType
    
    public init(range: NSRange, type: ActiveEntityType) {
        self.range = range
        self.type = type
    }
}

extension ActiveEntity {
    public var primaryText: String {
        switch self.type {
        case .email(let text, _):          return text
        case .hashtag(let text, _):        return text
        case .mention(let text, _):        return text
        case .url(let text, _, _, _):      return text
        }
    }
}
