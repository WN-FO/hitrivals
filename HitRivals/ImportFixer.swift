// This file fixes import issues with Supabase in the project
// It uses Swift's conditional compilation to handle the case when the Supabase module is unavailable

// First, use standard imports
import Foundation
import SwiftUI

// Now handle Supabase import conditionally
#if canImport(Supabase)
import Supabase

// Define a global constant to track Supabase availability
let SUPABASE_AVAILABLE = true

// Create type aliases to ensure compatibility
typealias SupabaseClientType = SupabaseClient
typealias SessionType = Session
typealias UserType = User
typealias AuthResponseType = AuthResponse

// Fallback implementation for the direct API in SupabaseService.swift
extension SupabaseClient {
    static func createDefault() -> SupabaseClient {
        return SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseUrl)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
}

#else
// Supabase is not available, create stub implementations

// Define a global constant to track Supabase availability
let SUPABASE_AVAILABLE = false

// Create stub types
struct SupabaseClientType {
    // Minimal implementation to compile
    init(supabaseURL: URL, supabaseKey: String) {
        print("Warning: Using stub SupabaseClient - Supabase module not available")
    }
}

struct SessionType {
    var accessToken: String = "stub-access-token"
}

struct UserType {
    var id: UUID = UUID()
}

struct AuthResponseType {}

// Stub implementation for the direct API in SupabaseService.swift
struct SupabaseClient {
    static func createDefault() -> SupabaseClientType {
        return SupabaseClientType(
            supabaseURL: URL(string: "https://example.com")!,
            supabaseKey: "stub-key"
        )
    }
}
#endif

// Public function to check and report Supabase availability
public func checkSupabaseStatus() {
    #if canImport(Supabase)
    print("✅ Supabase module is available and properly imported")
    #else
    print("❌ Supabase module is NOT available - using stub implementations")
    #endif
} 