//
//  ViewController.swift
//  SQLExample
//
//  Created by YYKJ0048 on 2021/9/30.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SQLManager.shared.connectDataBase()
//        SQLManager.shared.testConnect()
    }
    
    @IBAction func insetColumn() {
        SQLManager.shared.insetColumnInUserTable()
    }
    
    @IBAction func addUserInfo() {
        print("开始添加用户信息")
        let start = CACurrentMediaTime()

//        ["1@163.com", "2@163.com", "3@163.com", "4@163.com", "5@163.com"].forEach { string in
//            SQLManager.shared.addUserInfo(string, uName: "哈哈哈", uGender: "男")
//        }
        
        var infos: [UserModel] = []
        
        Array(1...10000)
            .forEach { index in
                let chat = UserChatSettingModel(price: "\(index + 10)")
                infos.append(UserModel(userID: "\(index + 1000)", email: "\(index)@163.com", name: "\(index)", gender: "男", chat: chat))
        }
        
        SQLManager.shared.addUserInfos(infos)
        
        print("结束添加用户信息: \(CACurrentMediaTime() - start)")
    }
    
    @IBAction func updateUserInfo() {
        let chat = UserChatSettingModel(price: "19999")
        SQLManager.shared.updateUserInfo(UserModel(userID: "1001", email: "-1@163.com", name: "嘻嘻嘻", gender: "女", chat: chat))
    }
    
    @IBAction func filterUserInfo() {
//        SQLManager.shared.filterUserInfo()
        SQLManager.shared.filterUserInfo("5@163.com") { userModel in
            print(userModel)
        }
    }
    
    @IBAction func filterJoinUserInfo() {
        print("开始获取用户信息")
        
        let start = CACurrentMediaTime()
        if let userModle = SQLManager.shared.filterUserAndChat("1002") {
            print(userModle)
        }
        
        print("结束获取用户信息: \(CACurrentMediaTime() - start)")
    }

    @IBAction func filterUsers() {
        print("开始获取用户信息")
        let start = CACurrentMediaTime()
        SQLManager.shared.filterUsers { users in
            print(users)
        }
        print("结束获取用户信息: \(CACurrentMediaTime() - start)")
    }
    
    @IBAction func deleteUsers() {
        SQLManager.shared.removeAllUsers()
    }
    
    @IBAction func deleteUser() {
//        SQLManager.shared.removeUser("1@163.com")
//        SQLManager.shared.sortUsers()
//        SQLManager.shared.insetMore()
        SQLManager.shared.searchLikeUser()
    }
}
