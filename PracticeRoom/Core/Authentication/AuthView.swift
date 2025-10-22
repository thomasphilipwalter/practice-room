//
//  AuthView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // App Title
                VStack(spacing: 8) {
                    Text("PracticeRoom")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in with your email")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 30)
                
                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if !email.isEmpty && !isValidEmail(email) {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                // Sign In Button
                Button(action: sendMagicLink) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Magic Link")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidEmail(email) && !email.isEmpty ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isValidEmail(email) || email.isEmpty || isLoading)
                
                // Success/Error Messages
                if let successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.callout)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                
                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                Spacer()
                
                // Info Text
                Text("We'll send you a magic link to sign in.\nNo password needed!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
        }
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                    successMessage = "Successfully signed in!"
                } catch {
                    errorMessage = "Failed to sign in. Please try again."
                }
            }
        })
    }
    
    // MARK: - Actions
    func sendMagicLink() {
        Task {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            defer { isLoading = false }
            
            do {
                try await supabase.auth.signInWithOTP(
                    email: email,
                    redirectTo: URL(string: "practiceroom://login-callback")
                )
                successMessage = "Check your email! We sent you a magic link to sign in."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}


#Preview {
    AuthView()
}
