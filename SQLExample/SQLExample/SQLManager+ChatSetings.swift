//
//  SQLManager+ChatSetings.swift
//  SQLExample
//
//  Created by YYKJ0048 on 2021/10/8.
//

import Foundation
import SQLite

// Expressions
fileprivate let index  = Expression<Int64>("index")
fileprivate let userID = Expression<String>("userID")
fileprivate let price  = Expression<String>("price")

extension SQLManager {
    /// 创建用户表
    /// - Parameter db: Connection
    func createChatSettingsTable(_ db: Connection) {
        do {
            try db.run(usersChatSetings.create(ifNotExists: true) { t in
                t.column(index, primaryKey: .autoincrement)
                // autoincrement：自动递增
                t.column(userID, unique: true)
                // unique：用于保证多列中是唯一值
                t.column(price, defaultValue: "0")
            })
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 添加用户的子信息到ChatSettings表
    /// - Parameters:
    ///   - userID: String
    ///   - chat: UserChatSettingModel
    func insetChatSetings(_ uUserID: String, chat: UserChatSettingModel) {
        do {
            try db.run(usersChatSetings.insert(userID <- uUserID, price <- chat.price))
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 更新用户的子信息到ChatSettings表
    /// - Parameters:
    ///   - userID: String
    ///   - chat: UserChatSettingModel
    func updateChatSetting(_ uUserID: String, chat: UserChatSettingModel) {
        let user = usersChatSetings.filter(userID == uUserID)
        do {
            try db.run(user.update(userID <- uUserID, price <- chat.price))
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 删除用户在ChatSettings表的子信息
    /// - Parameter userID: String
    func deleteChatSeting(_ uUserID: String) {
        let userInfo = usersChatSetings.filter(userID == uUserID)
        do {
            if try db.run(userInfo.delete()) > 0 {
                print("👍🏻👍🏻👍🏻 -------------- 删除所有用户成功 -------------- 👍🏻👍🏻👍🏻")
            } else {
                print("💥💥💥 -------------- 没有找到对应得用户 -------------- 💥💥💥")
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 获取ChatSettings表的子信息
    /// - Parameter userID: String
    func getChatSetting(_ uUserID: String, complete: ((_ chatSetting: UserChatSettingModel) -> Void)) {
        let query = usersChatSetings.filter(userID == uUserID)
        do {
            try db.prepare(query).forEach({ user in
                complete(UserChatSettingModel(price: user[price]))
            })
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 删除ChatSettings所有的子信息
    func removeAll() {
        do {
            if try db.run(usersChatSetings.delete()) > 0 {
                print("👍🏻👍🏻👍🏻 -------------- 删除所有用户成功 -------------- 👍🏻👍🏻👍🏻")
            } else {
                print("💥💥💥 -------------- 没有找到对应得用户 -------------- 💥💥💥")
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 使用Row转换成具体的模型
    /// - Parameter row: Row
    /// - Returns: UserChatSettingModel
    func getChatSetting(_ row: Row) -> UserChatSettingModel {
        UserChatSettingModel(price: row[price])
    }
}
