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
    
    var db: Connection?

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

    func connectDataBase() {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                             .userDomainMask,
                                                             true).first else {
            return
        }
                
        print("⚠️⚠️⚠️ -------------- Database Path: \(path)/db.sqlite3 -------------- ⚠️⚠️⚠️")
        
        do {
            db = try Connection("\(path)/db.sqlite3")
            db?.busyTimeout = 5
            db?.busyHandler { tries in
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
        guard let db = db else {
            return false
        }
        
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