//
//  AuthView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                
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
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // email field required, valid email required
                    if !viewModel.email.isEmpty && !isValidEmail(viewModel.email) {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                // Sign In Button
                Button(action: {
                    Task {
                        await viewModel.signInWithMagicLink(email: viewModel.email)
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Magic Link")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidEmail(viewModel.email) && !viewModel.email.isEmpty ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isValidEmail(viewModel.email) || viewModel.email.isEmpty || viewModel.isLoading) // TODO: isLoading might be why bugging when you press button
                
                // Success message
                if let successMessage = viewModel.successMessage {
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
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
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
                
            }
        }
        .onOpenURL(perform: { url in
            Task {
                await viewModel.handleMagicLinkCallback(url: url) // Perform sign in with magic link
            }
        })
    }
    
    // Validate email input
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
