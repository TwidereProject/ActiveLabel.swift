//
//  ActiveEntityType.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-11.
//

import Foundation

public enum ActiveEntityType {
    case mention(_ mention: String, userInfo: [AnyHashable: Any]? = nil)
    case hashtag(_ hashtag: String, userInfo: [AnyHashable: Any]? = nil)
    case email(_ email: String, userInfo: [AnyHashable: Any]? = nil)
    case url(original: String, trimmed: String, userInfo: [AnyHashable: Any]? = nil)
}
