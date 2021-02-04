//
//  ActiveEntityType.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-11.
//

import Foundation

public enum ActiveEntityType {
    case mention(_ text: String, userInfo: [AnyHashable: Any]? = nil)
    case hashtag(_ text: String, userInfo: [AnyHashable: Any]? = nil)
    case email(_ text: String, userInfo: [AnyHashable: Any]? = nil)
    case url(_ text: String, trimmed: String, url: String, userInfo: [AnyHashable: Any]? = nil)
}
