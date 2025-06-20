//
//  ReckyApp.swift
//  Recky
//
//  Created by Paul Winters on 6/17/25.
//

import FirebaseCore
import SwiftUI
import GoogleSignIn

@main
struct ReckyApp: App {
    @StateObject var session = SessionManager()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if session.user != nil {
                HomeView()
                    .environmentObject(session)
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
    }
}
