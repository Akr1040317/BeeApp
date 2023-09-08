//
//  User.swift
//  Bee
//
//  Created by Akshat Rastogi on 5/31/23.
//

import Foundation

struct Answer{
    let answers: [String]
    let score: Int
    let userId: String
    let quizId: String
    
}

struct User: Identifiable, Codable{
    let id: String
    let fullname: String
    let email: String
    
    var initials: String{
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname){
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        return ""
    }
}

extension User{
    static var MOCK_USER = User(id: NSUUID().uuidString, fullname: "Kobe Bryant", email: "bryant@gmail.com")
}
