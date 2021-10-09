//
//  SQLManager.swift
//  SQLExample
//
//  Created by YYKJ0048 on 2021/9/30.
//

import Foundation
import SQLite

class SQLManager {
    
    static let shared = SQLManager()
    
    open private(set) var db: Connection!
    
    // Table
    let users = Table("users")
    let usersChatSetings = Table("usersChatSetings")
    
    /// 获取/设置数据库的User Version
    var userVersion: Int32 {
        get {
            do {
                let version = try db?.scalar("PRAGMA user_version") as? Int64
                return Int32(version ?? 0)
            } catch {
                print("Get db user version errpr: \(error.localizedDescription)")
            }
            return 0
        } set {
            do {
                try db?.run("PRAGMA user_version = \(newValue)")
            } catch {
                print("Set db user version error: \(error.localizedDescription)")
            }
        }
    }
    
    /// 连接SQLite数据库
    func connectDataBase() {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                             .userDomainMask,
                                                             true).first else {
            return
        }
                
        print("⚠️⚠️⚠️ -------------- Database Path: \(path)/db.sqlite3 -------------- ⚠️⚠️⚠️")
        
        do {
            db = try Connection("\(path)/db.sqlite3")
            db.busyTimeout = 5
            db.busyHandler { tries in
                tries < 3
            }
            createUserTable(db)
            createChatSettingsTable(db)
        } catch {
            print("💥💥💥 -------------- \(error.localizedDescription) -------------- 💥💥💥")
        }
    }
    
    /// 判断表中是否存在该column，是就返回true，否就返回false
    /// - Parameters:
    ///   - table: String
    ///   - column: String
    /// - Returns: Bool
    func columns(table: String, column: String) -> Bool {
        do {
            var columns: [String] = []
            let statement = try db.prepare("PRAGMA table_info(" + table + ")")
            
            statement.forEach { row in
                if let column = row[1] as? String {
                    columns.append(column)
                }
            }
            
            let list = columns.filter { $0 == column }
            return !list.isEmpty
        } catch {
            return false
        }
    }
}
