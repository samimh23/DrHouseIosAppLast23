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
    @Published var saveSuccess = false
    
    @MainActor
    func saveGoals(userId: String) async {
        guard !userId.isEmpty else {
            errorMessage = "Invalid user ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let url = URL(string: "http://192.168.39.19:3000/goals/user/\(userId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No access token found"])
            }
            
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let jsonData = try JSONEncoder().encode(goals)
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                saveSuccess = true
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error \(httpResponse.statusCode)"])
            }
        } catch {
            errorMessage = error.localizedDescription
            saveSuccess = false
        }
    }
}

// MARK: - Preview Provider
#Preview {
    GoalSettingsView(navigationPath: .constant(NavigationPath()))
}
