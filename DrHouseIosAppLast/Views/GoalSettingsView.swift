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
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                
                // Save Button
                Button(action: {
                    Task {
                        await saveGoals()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(viewModel.isLoading ? "Saving..." : "Save Goals")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .alert("Goals Status", isPresented: $showAlert) {
            Button("OK") {
                if viewModel.saveSuccess {
                    navigateToHome()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    @MainActor
    private func saveGoals() async {
        do {
            guard let userId = UserDefaults.standard.string(forKey: "userId") else {
                alertMessage = "Error: User ID not found"
                showAlert = true
                return
            }
            
            await viewModel.saveGoals(userId: userId)
            
            if viewModel.saveSuccess {
                UserDefaults.standard.set(false, forKey: "isFirstLogin")
                alertMessage = "Goals saved successfully!"
                showAlert = true
            } else {
                alertMessage = viewModel.errorMessage ?? "Failed to save goals. Please try again."
                showAlert = true
            }
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func navigateToHome() {
        withAnimation {
            navigationPath = NavigationPath()
            navigationPath.append("home")
        }
    }
}

// MARK: - GoalInputField View
struct GoalInputField: View {
    @Binding var value: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            HStack {
                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...getMaxValue(for: title)) { _ in
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                }
                .accentColor(.blue)
                
                Text("\(value)")
                    .font(.system(.body, design: .rounded))
                    .frame(minWidth: 40)
                    .foregroundColor(.blue)
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
