//
//  LoginView.swift
//  Ibtida
//
//  Authentication view for login and signup
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedGender: UserGender?
    @State private var showForgotPassword = false
    
    var body: some View {
        ZStack {
            // Warm background with Islamic pattern
            WarmBackgroundView()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top decorative section
                    topSection
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    
                    // Main card
                    VStack(spacing: 28) {
                        // Welcome text
                        welcomeSection
                        
                        // Form
                        formSection
                        
                        // Actions
                        actionsSection
                        
                        // Social login
                        socialLoginSection
                        
                        // Toggle mode
                        toggleModeSection
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.warmCard(colorScheme))
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(authService.errorMessage != nil)) {
                Button("OK") { authService.errorMessage = nil }
            } message: {
                Text(authService.errorMessage ?? "")
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    // MARK: - Top Section
    
    private var topSection: some View {
        VStack(spacing: 20) {
            // Islamic geometric pattern inspired logo
            ZStack {
                // Decorative circles
                Circle()
                    .strokeBorder(
                        LinearGradient.goldAccent(gender: ThemeManager.shared.userGender, scheme: colorScheme),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                
                Circle()
                    .strokeBorder(
                        LinearGradient.goldAccent.opacity(0.5),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                
                // Central icon
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(LinearGradient.goldAccent(gender: ThemeManager.shared.userGender, scheme: colorScheme))
            }
            
            // App name with Arabic calligraphy style
            VStack(spacing: 8) {
                Text("Ibtida")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text("ابدأ")
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundColor(Color.mutedGold)
                    .environment(\.layoutDirection, .rightToLeft)
                
                Text(isSignUp ? "Begin your journey" : "Welcome back, traveler")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Text(isSignUp ? "Create Account" : "Sign In")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
            
            Text(isSignUp ? "Join our community of believers" : "Continue your spiritual journey")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            if isSignUp {
                CustomTextField(
                    icon: "person",
                    placeholder: "Full Name",
                    text: $name
                )
            }
            
            CustomTextField(
                icon: "envelope",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            
            CustomTextField(
                icon: "lock",
                placeholder: "Password",
                text: $password,
                isSecure: true
            )
            
            if isSignUp {
                CustomTextField(
                    icon: "lock",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isSecure: true
                )
                
                // Gender Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("I am a:")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        genderButton(gender: .brother)
                        genderButton(gender: .sister)
                    }
                }
            }
            
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button(action: handleAuth) {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                    .background(
                        LinearGradient.goldAccent(gender: ThemeManager.shared.userGender, scheme: colorScheme)
                    )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.mutedGold.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(authService.isLoading || !isFormValid)
            .opacity(isFormValid ? 1 : 0.5)
            
            if !isSignUp {
                Button("Forgot Password?") {
                    showForgotPassword = true
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.mutedGold)
            }
        }
    }
    
    // MARK: - Social Login Section
    
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(Color.warmBorder(colorScheme))
                    .frame(height: 1)
                
                Text("or")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                    .padding(.horizontal, 12)
                
                Rectangle()
                    .fill(Color.warmBorder(colorScheme))
                    .frame(height: 1)
            }
            
            Button(action: handleGoogleSignIn) {
                HStack(spacing: 12) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 22))
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.warmSurface(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.warmBorder(colorScheme), lineWidth: 1.5)
                        )
                )
                .foregroundColor(Color.warmText(colorScheme))
            }
            .disabled(authService.isLoading)
            .buttonStyle(SmoothButtonStyle())
        }
    }
    
    // MARK: - Toggle Mode Section
    
    private var toggleModeSection: some View {
        HStack(spacing: 6) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(.system(size: 15))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            
            Button(isSignUp ? "Sign In" : "Sign Up") {
                HapticFeedback.light()
                withAnimation(.spring(response: 0.3)) {
                    isSignUp.toggle()
                    clearForm()
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color.mutedGold)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty &&
                   !email.isEmpty &&
                   !password.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6 &&
                   selectedGender != nil
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func handleAuth() {
        Task {
            if isSignUp {
                guard let gender = selectedGender else {
                    return
                }
                try? await authService.signUp(name: name, email: email, password: password, gender: gender)
            } else {
                try? await authService.signIn(email: email, password: password)
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            try? await authService.signInWithGoogle()
        }
    }
    
    private func clearForm() {
        name = ""
        email = ""
        password = ""
        confirmPassword = ""
        selectedGender = nil
    }
    
    // MARK: - Gender Button
    
    private func genderButton(gender: UserGender) -> some View {
        Button(action: {
            HapticFeedback.light()
            selectedGender = gender
        }) {
            HStack(spacing: 10) {
                Image(systemName: gender == .brother ? "person.fill" : "person.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedGender == gender ? .white : Color.mutedGold)
                
                Text(gender.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedGender == gender ? .white : Color.warmText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                selectedGender == gender
                    ? LinearGradient.goldAccent
                    : LinearGradient(
                        colors: [Color.warmSurface(colorScheme)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        selectedGender == gender
                            ? Color.clear
                            : Color.warmBorder(colorScheme),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: selectedGender == gender
                    ? Color.mutedGold.opacity(0.3)
                    : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.mutedGold.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.mutedGold)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.warmText(colorScheme))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.warmText(colorScheme))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.warmSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.warmBorder(colorScheme), lineWidth: 1)
                )
        )
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Reset Password")
                    .font(.title2.weight(.bold))
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                CustomTextField(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )
                
                Button(action: resetPassword) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(email.isEmpty || authService.isLoading)
                
                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Email Sent", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Check your email for a password reset link.")
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await authService.resetPassword(email: email)
                showSuccess = true
            } catch {
                // Error handled by authService
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
