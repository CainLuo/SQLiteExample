//
//  SQLManager+Users.swift
//  SQLExample
//
//  Created by YYKJ0048 on 2021/10/8.
//

import Foundation
import SQLite

// Table
fileprivate let users = Table("users")

// Expressions
fileprivate let index = Expression<Int64>("index")
fileprivate let userID = Expression<String>("userID")
fileprivate let email = Expression<String>("email")
fileprivate let balance = Expression<Double>("balance")
fileprivate let verified = Expression<Bool>("verified")
fileprivate let name = Expression<String?>("name")
fileprivate let gender = Expression<String?>("gender")

extension SQLManager {
    /// 创建用户表
    /// - Parameter db: Connection
    func createUserTable(_ db: Connection?) {
        guard let db = db else {
            return
        }
        
        do {
            try db.run(users.create(ifNotExists: true) { t in
                // autoincrement：自动递增
                t.column(index, primaryKey: .autoincrement)
                // unique：用于保证多列中是唯一值
                t.column(userID, unique: true)
                t.column(email, unique: true)
                t.column(name)
                // defaultValue：默认值
                t.column(balance, defaultValue: 0.0)
                t.column(verified, defaultValue: false)
            })
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 新建Users表的Gender行
    func insetColumnInUserTable() {
        guard !columns(table: "users", column: "gender") else {
            print("💥💥💥 -------------- 插入失败，表中已有该列 -------------- 💥💥💥")
            return
        }
        
        do {
            try db?.run(users.addColumn(gender))
            userVersion += 1
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 添加用户信息到Users表
    /// - Parameters:
    ///   - uEmail: String
    ///   - uName: String
    ///   - uGender: String
    func addUserInfo(_ model: UserModel) {
        do {
            try db?.run(users.insert(email <- model.email, name <- model.name, gender <- model.gender))
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 批量添加用户信息到Users表
    /// - Parameter models: [UserModel]
    func addUserInfos(_ models: [UserModel]) {
        do {
            // 开启SQLite的事务
            try db?.transaction {
                models.forEach { model in
                    do {
                        try db?.run(users.insert(userID <- model.userID, email <- model.email, name <- model.name, gender <- model.gender))
                    } catch {
                        print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
                    }
                }
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 更新Users表的用户信息
    /// - Parameters:
    ///   - uEmail: String
    ///   - uName: String
    ///   - uGender: String
    func updateUserInfo(_ model: UserModel) {
        do {
            try db?.run(users.update(email <- model.email, name <- model.name, gender <- model.gender))
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 遍地Users表的所有用户
    func filterUsers() {
        do {
            try db?.transaction {
                do {
                    try db?.prepare(users).forEach({ user in
                        print("User: \(user[index]), \(user[email]), \(String(describing: user[name])), \(user[balance]), \(user[verified]), \(String(describing: user[gender]))")
                    })
                } catch {
                    print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
                }
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 选择Users表里的Email字段
    func filterEmails() {
        let query = users.select(email)
        do {
            try db?.prepare(query).forEach({ user in
                print("User: \(user[email]))")
            })
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 获取Users表指定邮箱的用户
    /// - Parameter uEmail: String
    func filterUserInfo(_ uEmail: String) {
        // filter和where是一样的效果
//        let query = users.filter(email == uEmail)
        let query = users.where(email == uEmail)

        do {
            try db?.prepare(query).forEach({ user in
                print("User: \(user[index]), \(user[email]), \(String(describing: user[name])), \(user[balance]), \(user[verified]), \(String(describing: user[gender]))")
            })
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 删除所有用户信息
    func removeAllUsers() {
        guard let db = db else {
            return
        }
        do {
            if try db.run(users.delete()) > 0 {
                print("👍🏻👍🏻👍🏻 -------------- 删除所有用户成功 -------------- 👍🏻👍🏻👍🏻")
            } else {
                print("💥💥💥 -------------- 没有找到对应得用户 -------------- 💥💥💥")
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 删除指定邮箱的用户信息
    /// - Parameter uEmail: String
    func removeUser(_ uEmail: String) {
        let uEmail = users.filter(email == uEmail)
        guard let db = db else {
            return
        }
        do {
            if try db.run(uEmail.delete()) > 0 {
                print("👍🏻👍🏻👍🏻 -------------- 删除所有用户成功 -------------- 👍🏻👍🏻👍🏻")
            } else {
                print("💥💥💥 -------------- 没有找到对应得用户 -------------- 💥💥💥")
            }
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
}