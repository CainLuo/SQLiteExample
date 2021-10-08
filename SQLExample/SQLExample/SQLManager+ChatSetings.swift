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
fileprivate let id    = Expression<String>("id")
fileprivate let price = Expression<String>("price")

extension SQLManager {
    /// 创建用户表
    /// - Parameter db: Connection
    func createChatSettingsTable(_ db: Connection) {
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
    
    /// 添加用户的子信息到ChatSettings表
    /// - Parameters:
    ///   - userID: String
    ///   - chat: UserChatSettingModel
    func insetChatSetings(_ userID: String, chat: UserChatSettingModel) {
        do {
            try db.run(chatSetings.insert(id <- userID, price <- chat.price))
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 更新用户的子信息到ChatSettings表
    /// - Parameters:
    ///   - userID: String
    ///   - chat: UserChatSettingModel
    func updateChatSetting(_ userID: String, chat: UserChatSettingModel) {
        let user = chatSetings.filter(id == userID)
        do {
            try db.run(user.update(id <- userID, price <- chat.price))
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 删除用户在ChatSettings表的子信息
    /// - Parameter userID: String
    func deleteChatSeting(_ userID: String) {
        let userInfo = chatSetings.filter(id == userID)
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
    func getChatSetting(_ userID: String, complete: ((_ chatSetting: UserChatSettingModel) -> Void)) {
        let query = chatSetings.filter(id == userID)
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
            if try db.run(chatSetings.delete()) > 0 {
                print("👍🏻👍🏻👍🏻 -------------- 删除所有用户成功 -------------- 👍🏻👍🏻👍🏻")
            } else {
                print("💥💥💥 -------------- 没有找到对应得用户 -------------- 💥💥💥")
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
}
