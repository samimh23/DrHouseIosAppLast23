//
//  GoalSettingsViewModel.swift
//  DrHouseIosAppLast
//
//  Created by Mac Mini 11 on 4/12/2024.
//

import Foundation
import SwiftUI
class GoalSettingsViewModel: ObservableObject {
    @Published var goals = Goal(steps: 10000, water: 8, sleepHours: 8, coffeeCups: 2, workout: 30)
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func saveGoals(userId: String) async throws {
        guard !userId.isEmpty else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "http://192.168.250.19:3000/goals/user/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get access token
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No access token found"])
        }
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let jsonData = try JSONEncoder().encode(goals)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save goals"])
        }
    }
}

// Add some visual styling components

// Add custom modifiers for consistent styling
extension View {
    func goalCardStyle() -> some View {
        self.modifier(GoalCardModifier())
    }
}

struct GoalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}
