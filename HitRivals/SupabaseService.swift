import Foundation
#if canImport(Supabase)
import Supabase
#endif

class SupabaseService {
    static let shared = SupabaseService()
    
    #if canImport(Supabase)
    let client: SupabaseClient
    #else
    let client: SupabaseClientType
    #endif
    
    private init() {
        #if canImport(Supabase)
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseUrl)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        #else
        client = SupabaseClientType(
            supabaseURL: URL(string: SupabaseConfig.supabaseUrl)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        #endif
        
        // Check if Supabase is properly initialized
        checkSupabaseStatus()
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws -> AuthResponse {
        #if canImport(Supabase)
        return try await client.auth.signUp(
            email: email,
            password: password
        )
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        #if canImport(Supabase)
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        return response
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func signOut() async throws {
        #if canImport(Supabase)
        try await client.auth.signOut()
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func resetPassword(email: String) async throws {
        #if canImport(Supabase)
        try await client.auth.resetPasswordForEmail(email)
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func signInWithOTP(email: String) async throws {
        #if canImport(Supabase)
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "com.hitrivals.app://login-callback")
        )
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    // MARK: - Profile
    
    struct Profile: Codable {
        var username: String?
        var fullName: String?
        var avatarUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case username
            case fullName = "full_name"
            case avatarUrl = "avatar_url"
        }
    }
    
    func getProfile(userId: UUID) async throws -> Profile {
        #if canImport(Supabase)
        return try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func updateProfile(userId: UUID, profile: Profile) async throws {
        #if canImport(Supabase)
        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: userId)
            .execute()
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    // Non-async methods that safely access potentially async properties
    func getUser() async throws -> User? {
        #if canImport(Supabase)
        return try await client.auth.currentUser
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func getSession() async throws -> Session? {
        #if canImport(Supabase)
        return try await client.auth.session
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
    
    func refreshSession() async throws -> Session {
        #if canImport(Supabase)
        return try await client.auth.refreshSession()
        #else
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase module not available"])
        #endif
    }
} 