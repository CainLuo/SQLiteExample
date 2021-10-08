//
//  SQLManager+ChatSetings.swift
//  SQLExample
//
//  Created by YYKJ0048 on 2021/10/8.
//

import Foundation
import SQLite

// Table
fileprivate let chatSetings = Table("chatSetings")

// Expressions
fileprivate let id = Expression<Int64>("id")
fileprivate let price = Expression<String>("price")

extension SQLManager {
    /// 创建用户表
    /// - Parameter db: Connection
    func createChatSettingsTable(_ db: Connection?) {
        guard let db = db else {
            return
        }
        
        do {
            try db.run(chatSetings.create(ifNotExists: true) { t in
                // autoincrement：自动递增
                t.column(id, unique: true)
                // unique：用于保证多列中是唯一值
                t.column(price, defaultValue: "0")
            })
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
}
