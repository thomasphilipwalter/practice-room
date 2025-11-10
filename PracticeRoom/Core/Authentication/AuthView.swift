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
            Color(red: 122/255, green: 54/255, blue: 17/255).ignoresSafeArea()
            VStack(spacing: 24) {
                // App Title
                VStack(spacing: 8) {
                    Text("PracticeRoom")
                        .font(.custom("Merriweather", size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize))
                        .fontWeight(.bold)
                    
                    Text("Sign in with your email")
                        .font(.custom("Merriweather-Regular", size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 30)
                
                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField(
                        text: $viewModel.email,
                        prompt: Text("Email")
                            .foregroundColor(.white.opacity(0.7)) // placeholder color
                    ) {
                        // optional label
                        Text("")
                    }
                    .font(.custom("Merriweather-Regular", size: 15))
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.brown))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    
                    // Validate Email
                    if !viewModel.email.isEmpty && !isValidEmail(viewModel.email) {
                        Text("Please enter a valid email address")
                            .font(.custom("Merriweather-Regular", size: 13))
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
                            .tint(.black)
                    } else {
                        Text("Send Magic Link")
                            .font(.custom("Merriweather-Regular", size: 17))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidEmail(viewModel.email) && !viewModel.email.isEmpty ? Color.white.opacity(0.7) : Color.white.opacity(0.5))
                .foregroundColor(.black)
                .cornerRadius(10)
                .disabled(!isValidEmail(viewModel.email) || viewModel.email.isEmpty || viewModel.isLoading)
                
                
                // Success Message
                if let successMessage = viewModel.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.circle.fill")
                            .foregroundColor(.white)
                        Text(successMessage)
                            .font(.custom("Merriweather-Regular", size: 15))
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(errorMessage)
                            .font(.custom("Merriweather-Regular", size: 15))
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 32)
        }
        .onOpenURL(perform: { url in
            Task {
                await viewModel.handleMagicLinkCallback(url: url)   // Call when view opened from magic link
            }
        })
    }
    
    // function isValidEmail:
    // - Checks if the email matches *@ format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}


#Preview {
    AuthView()
}
