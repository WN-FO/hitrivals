import SwiftUI
import Supabase

struct AuthView: View {
    @State var email = ""
    @State var password = ""
    @State var isLoading = false
    @State var result: Result<Void, Error>?
    @State var isSigningUp = false
    @StateObject private var appModel = AppModel.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "figure.boxing")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("HitRivals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                    }
                    
                    Section {
                        if isSigningUp {
                            Button("Sign Up") {
                                signUpTapped()
                            }
                            .disabled(isLoading)
                        } else {
                            Button("Sign In") {
                                signInTapped()
                            }
                            .disabled(isLoading)
                        }
                        
                        Button(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                            isSigningUp.toggle()
                        }
                        
                        if !isSigningUp {
                            Button("Send Magic Link") {
                                sendMagicLinkTapped()
                            }
                            .disabled(isLoading)
                        }
                        
                        if isLoading {
                            ProgressView()
                        }
                    }
                    
                    if let result = result {
                        Section {
                            switch result {
                            case .success:
                                Text("Success! Check your inbox or wait for redirect.")
                                    .foregroundColor(.green)
                            case .failure(let error):
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onOpenURL { url in
            print("Received URL: \(url)")
            Task {
                do {
                    try await SupabaseService.shared.client.auth.session(from: url)
                    result = .success(())
                    // If session is successful, update the login state
                    DispatchQueue.main.async {
                        appModel.isLoggedIn = true
                    }
                } catch {
                    print("Error handling URL: \(error)")
                    result = .failure(error)
                }
            }
        }
    }
    
    func signInTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                _ = try await SupabaseService.shared.signIn(email: email, password: password)
                result = .success(())
                
                // Update login state after successful sign in
                DispatchQueue.main.async {
                    appModel.isLoggedIn = true
                }
            } catch {
                print("Sign in error: \(error)")
                result = .failure(error)
            }
        }
    }
    
    func signUpTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                _ = try await SupabaseService.shared.signUp(email: email, password: password)
                result = .success(())
            } catch {
                print("Sign up error: \(error)")
                result = .failure(error)
            }
        }
    }
    
    func sendMagicLinkTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await SupabaseService.shared.signInWithOTP(email: email)
                result = .success(())
            } catch {
                print("Magic link error: \(error)")
                result = .failure(error)
            }
        }
    }
} 