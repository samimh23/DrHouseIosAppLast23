//
//  GoalSettingsView.swift
//  DrHouseIosAppLast
//
//  Created by Mac Mini 11 on 4/12/2024.
//

import SwiftUI

struct GoalSettingsView: View {
    @StateObject private var viewModel = GoalSettingsViewModel()
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Set Your Health Goals")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Goal input fields
                GoalInputField(value: $viewModel.goals.steps,
                             title: "Daily Steps",
                             icon: "figure.walk")
                GoalInputField(value: $viewModel.goals.water,
                             title: "Water Intake (glasses)",
                             icon: "drop.fill")
                GoalInputField(value: $viewModel.goals.sleepHours,
                             title: "Sleep Hours",
                             icon: "moon.fill")
                GoalInputField(value: $viewModel.goals.coffeeCups,
                             title: "Coffee Limit",
                             icon: "cup.and.saucer.fill")
                GoalInputField(value: $viewModel.goals.workout,
                             title: "Workout Minutes",
                             icon: "figure.walk")
                
                Button("Save Goals") {
                    Task {
                        await saveGoals()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            .padding()
        }
    }
    
    private func saveGoals() async {
        do {
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            try await viewModel.saveGoals(userId: userId)
            
            // Update first login status
            UserDefaults.standard.set(false, forKey: "isFirstLogin")
            
            // Navigate to home
            DispatchQueue.main.async {
                withAnimation {
                    navigationPath.removeLast() // Remove goals view
                    navigationPath.append("home") // Go to home
                }
            }
        } catch {
            // Handle error
            print("Error saving goals: \(error.localizedDescription)")
        }
    }
}

struct GoalInputField: View {
    @Binding var value: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            
            HStack {
                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...getMaxValue(for: title)) { _ in
                    // Haptic feedback when sliding
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                }
                .accentColor(.blue)
                
                Text("\(value)")
                    .font(.system(.body, design: .rounded))
                    .frame(minWidth: 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    private func getMaxValue(for title: String) -> Double {
        switch title {
        case "Daily Steps":
            return 20000
        case "Water Intake (glasses)":
            return 12
        case "Sleep Hours":
            return 12
        case "Coffee Limit":
            return 10
        case "Workout Minutes":
            return 180
        default:
            return 100
        }
    }
}
