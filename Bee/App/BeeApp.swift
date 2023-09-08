//
//  BeeApp.swift
//  Bee
//
//  Created by Akshat Rastogi on 5/31/23.
//

import SwiftUI
import Firebase

@main
struct BeeApp: App {
    @StateObject var viewModel = AuthViewModel()
    
    init(){
        FirebaseApp.configure()
    }
    
    
    var body: some Scene {
        WindowGroup {
            NavigationView{
                ContentView()
                    .environmentObject(viewModel)
            }
        }
    }
}
