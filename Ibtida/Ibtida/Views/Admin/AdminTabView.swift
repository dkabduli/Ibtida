//
//  AdminTabView.swift
//  Ibtida
//
//  Admin-only tab root. Shown only when authService.isAdmin; otherwise not rendered.
//

import SwiftUI

struct AdminTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            AdminDashboardView()
        }
        .tabItem {
            Label("Admin", systemImage: "shield.checkered")
        }
    }
}
