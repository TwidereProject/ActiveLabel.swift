//
//  ActiveEntityType.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-11.
//

import Foundation

public enum ActiveEntityType {
    case mention(String)
    case hashtag(String)
    case email(String)
    case url(original: String, trimmed: String)
}
