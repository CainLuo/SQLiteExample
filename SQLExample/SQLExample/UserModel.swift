//
//  UserModel.swift
//  SQLExample
//
//  Created by YYKJ0048 on 2021/10/8.
//

import Foundation
import ObjectMapper

struct UserModel {
    var userID = ""
    var email = ""
    var balance = 0.0
    var verified = false
    var name = ""
    var gender = ""
}

extension UserModel: Mappable {
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        userID <- map["userID"]
        email <- map["email"]
        balance <- map["balance"]
        verified <- map["verified"]
        name <- map["name"]
        gender <- map["gender"]
    }
}
