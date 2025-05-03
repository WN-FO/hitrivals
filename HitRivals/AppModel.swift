import Foundation
import SwiftUI
import Supabase

class AppModel: ObservableObject {
    static let shared = AppModel()
    
    @Published var isLoggedIn: Bool = false
    
    private init() {
        // Check for existing session at startup
        Task {
            do {
                if try await SupabaseService.shared.getSession() != nil {
                    DispatchQueue.main.async {
                        self.isLoggedIn = true
                    }
                } else {
                    print("No active session found during initialization")
                }
            } catch {
                print("Error checking session: \(error)")
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await SupabaseService.shared.signIn(email: email, password: password)
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
    
    func signUp(email: String, password: String) async throws {
        _ = try await SupabaseService.shared.signUp(email: email, password: password)
    }
    
    func signOut() async throws {
        try await SupabaseService.shared.signOut()
        DispatchQueue.main.async {
            self.isLoggedIn = false
        }
    }
} 