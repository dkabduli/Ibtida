//
//  GenderOnboardingView.swift
//  Ibtida
//
//  Onboarding view for gender selection (required for all users)
//

import SwiftUI
import FirebaseAuth

struct GenderOnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedGender: UserGender?
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            WarmBackgroundView()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.mutedGold)
                    
                    Text(AppStrings.welcomeToApp)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text("Please select your gender to personalize your experience")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Gender Selection
                VStack(spacing: 16) {
                    genderButton(gender: .brother)
                    genderButton(gender: .sister)
                }
                .padding(.horizontal, 24)
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }
                
                // Continue Button
                Button(action: saveGender) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedGender != nil
                            ? AnyShapeStyle(LinearGradient.goldAccent)
                            : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(selectedGender == nil || isSaving)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Gender Button
    
    private func genderButton(gender: UserGender) -> some View {
        Button(action: {
            HapticFeedback.light()
            selectedGender = gender
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            selectedGender == gender
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.mutedGold.opacity(0.2),
                                            Color.deepGold.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(Color.warmSurface(colorScheme))
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: gender == .brother ? "person.fill" : "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(
                            selectedGender == gender
                                ? .mutedGold
                                : Color.warmSecondaryText(colorScheme)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(gender.displayName)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text(gender == .brother ? "Personalized for brothers" : "Personalized for sisters")
                        .font(.system(size: 14))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                Spacer()
                
                if selectedGender == gender {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.mutedGold)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warmCard(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                selectedGender == gender
                                    ? LinearGradient.goldAccent
                                    : LinearGradient(
                                        colors: [Color.warmBorder(colorScheme)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                lineWidth: selectedGender == gender ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: selectedGender == gender
                    ? Color.mutedGold.opacity(0.2)
                    : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Save Gender
    
    private func saveGender() {
        guard let gender = selectedGender,
              let uid = authService.userUID else {
            errorMessage = "Please select a gender"
            return
        }
        
        isSaving = true
        errorMessage = nil
        HapticFeedback.medium()
        
        Task {
            do {
                // Update user profile in Firestore
                try await UserProfileFirestoreService.shared.updateGenderAndOnboarding(
                    uid: uid,
                    gender: gender,
                    onboardingCompleted: true
                )
                
                await MainActor.run {
                    isSaving = false
                    HapticFeedback.success()
                    
                    // Update theme manager
                    ThemeManager.shared.userGender = gender
                }
                
                #if DEBUG
                print("✅ GenderOnboardingView: Saved gender - \(gender.rawValue)")
                #endif
                
                // Refresh the root view by posting notification
                NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save. Please try again."
                    HapticFeedback.error()
                }
                
                #if DEBUG
                print("❌ GenderOnboardingView: Error saving gender - \(error)")
                #endif
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GenderOnboardingView()
        .environmentObject(AuthService.shared)
}
