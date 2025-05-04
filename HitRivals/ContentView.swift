//
//  ContentView.swift
//  HitRivals
//
//  Created by Will Nichols on 4/26/25.
//

import SwiftUI
import PhotosUI
import Supabase
import Combine

// MARK: - Theme Manager
import SwiftUI
import PhotosUI
import Supabase
import Combine

// Custom Theme Manager
struct HRTheme {
    // Colors based on provided palette
    static let blue = Color(hex: "#002868")
    static let blueBorder = Color(hex: "#001845")
    static let blueShadow = Color(hex: "#001430")
    
    static let red = Color(hex: "#bf0d3e")
    static let redBorder = Color(hex: "#a00a34")
    static let redShadow = Color(hex: "#8f0930")
    
    static let white = Color.white
    static let whiteBorder = Color(hex: "#e0e0e0")
    static let whiteShadow = Color(hex: "#cccccc")
    
    static let gold = Color(hex: "#FFD700")
    static let goldBorder = Color(hex: "#e6c200")
    static let goldShadow = Color(hex: "#ccac00")
    
    // Text colors
    static let blueText = Color.white
    static let redText = Color.white
    static let whiteText = Color(hex: "#002868")
    static let goldText = Color(hex: "#002868")
    
    // Background
    static let background = Color(hex: "#f0f0f0")
    
    // Accent colors for variety
    static let neonGreen = Color(hex: "#ADFF2F")
    static let hotPink = Color(hex: "#FF69B4")
    
    // Fonts
    struct Fonts {
        static let title = Font.custom("ComicSansMS-Bold", size: 24)
        static let subtitle = Font.custom("ComicSansMS-Bold", size: 18)
        static let body = Font.custom("ComicSansMS", size: 16)
        static let caption = Font.custom("ComicSansMS", size: 12)
    }
    
    // Animations
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// Extension for button style
struct CPFMButtonStyle: ButtonStyle {
    var bgColor: Color = HRTheme.blue
    var borderColor: Color = HRTheme.blueBorder
    var shadowColor: Color = HRTheme.blueShadow
    var textColor: Color = HRTheme.blueText
    var isLarge: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HRTheme.Fonts.body)
            .padding(.vertical, isLarge ? 12 : 8)
            .padding(.horizontal, isLarge ? 24 : 16)
            .background(bgColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 3)
                    .offset(x: configuration.isPressed ? 0 : 0, y: configuration.isPressed ? 0 : 0)
            )
            .shadow(color: shadowColor, radius: 0, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(HRTheme.defaultAnimation, value: configuration.isPressed)
    }
}

// Custom Card Style
struct CPFMCardStyle: ViewModifier {
    var bgColor: Color = HRTheme.white
    var borderColor: Color = HRTheme.blueBorder
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(bgColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func cpfmCard(bgColor: Color = HRTheme.white, borderColor: Color = HRTheme.blueBorder) -> some View {
        self.modifier(CPFMCardStyle(bgColor: bgColor, borderColor: borderColor))
    }
}

// Animated Logo Text
struct AnimatedText: View {
    let text: String
    let baseSize: CGFloat
    @State private var animationTrigger = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.custom("ComicSansMS-Bold", size: baseSize))
                    .foregroundColor(index % 2 == 0 ? HRTheme.red : HRTheme.blue)
                    .scaleEffect(animationTrigger ? 1 + (0.2 * sin(Double(index) * 0.5)) : 1)
                    .offset(y: animationTrigger ? -2 + (4 * sin(Double(index))) : 0)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationTrigger = true
            }
        }
    }
}

// Emoji with Bounce
struct BouncyEmoji: View {
    let emoji: String
    @State private var isAnimating = false
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 28))
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Models
struct Profile: Identifiable, Codable {
    var id: String
    var username: String?
    var avatarUrl: String?
    var hitRate: Double?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case hitRate = "hit_rate"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Game: Identifiable, Codable {
    var id: Int
    var homeTeam: String
    var awayTeam: String
    var homeTeamAbbr: String?
    var awayTeamAbbr: String?
    var startTime: Date
    var status: String
    var winner: String?
    var createdAt: Date?
    var userVote: String?
    var sportType: SportType = .mlb
    
    enum SportType: String, Codable {
        case mlb
        case nba
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeTeamAbbr = "home_team_abbr"
        case awayTeamAbbr = "away_team_abbr"
        case startTime = "start_time"
        case status
        case winner
        case createdAt = "created_at"
        case sportType = "sport_type"
    }
}

struct Prediction: Identifiable, Codable {
    var id: Int
    var userId: String
    var gameId: Int
    var prediction: String
    var isCorrect: Bool?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case gameId = "game_id"
        case prediction
        case isCorrect = "is_correct"
        case createdAt = "created_at"
    }
}

struct Friend: Identifiable, Codable {
    var id: Int
    var userId: String
    var friendId: String
    var createdAt: Date?
    var username: String?
    var avatarUrl: String?
    var hitRate: Double = 0.0
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case createdAt = "created_at"
    }
}

struct FriendRequest: Identifiable, Codable {
    var id: Int
    var senderId: String
    var receiverId: String
    var status: String
    var createdAt: Date?
    var username: String?
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
    }
}

struct UserRanking: Identifiable {
    var id: String
    var username: String
    var avatarUrl: String?
    var hitRate: Double
    var rank: Int
}

// MARK: - View Models
// ProfileViewModel adapted to use SupabaseService
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hitRate: Double = 0.0
    @Published var rank: Int?
    @Published var avatarImage: UIImage?
    @Published var username: String = ""
    
    func getProfile(userId: String) {
        self.isLoading = true
        
        Task {
            do {
                // Convert the string userId to UUID
                guard let userUUID = UUID(uuidString: userId) else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.errorMessage = "Invalid user ID format"
                        self.isLoading = false
                    }
                    return
                }
                
                // Get profile using SupabaseService
                let supaProfile = try await SupabaseService.shared.getProfile(userId: userUUID)
                
                // Convert to our app's Profile model
                let appProfile = Profile(
                    id: userId,
                    username: supaProfile.username,
                    avatarUrl: supaProfile.avatarUrl,
                    hitRate: 0, // Will calculate this separately
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.profile = appProfile
                    self.username = appProfile.username ?? ""
                    self.isLoading = false
                    
                    if let avatarUrl = appProfile.avatarUrl {
                        self.downloadAvatar(avatarUrl)
                    }
                }
                
                // Get hit rate
                self.fetchHitRate(userId: userId)
                
                // Get rank
                self.fetchRank(userId: userId)
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func fetchHitRate(userId: String) {
        Task {
            do {
                // Using Supabase to fetch predictions
                // In a real app, you'd implement this with your specific table structure
                
                // This is a placeholder implementation
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // Mock hit rate for now
                    self.hitRate = 75.0
                }
            } catch {
                print("Error fetching hit rate: \(error)")
            }
        }
    }
    
    func fetchRank(userId: String) {
        Task {
            do {
                // Using Supabase to fetch profiles ordered by hit_rate
                // In a real app, you'd implement this with your specific table structure
                
                // This is a placeholder implementation
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // Mock rank for now
                    self.rank = 3
                }
            } catch {
                print("Error fetching rank: \(error)")
            }
        }
    }
    
    func downloadAvatar(_ path: String) {
        Task {
            do {
                // This is a placeholder - you would implement this with your storage setup
                // For now, we're not loading the actual image
                print("Downloading avatar from path: \(path)")
            } catch {
                print("Error downloading avatar: \(error)")
            }
        }
    }
    
    func uploadAvatar(image: UIImage, userId: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        let filePath = "\(userId).jpg"
        
        Task {
            do {
                // This is a placeholder - you would implement this with your storage setup
                print("Uploading avatar for user: \(userId)")
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.avatarImage = image
                    self.profile?.avatarUrl = filePath
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = "Error uploading avatar: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateProfile(userId: String, username: String) {
        Task {
            do {
                guard let userUUID = UUID(uuidString: userId) else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.errorMessage = "Invalid user ID format"
                    }
                    return
                }
                
                var supaProfile = try await SupabaseService.shared.getProfile(userId: userUUID)
                supaProfile.username = username
                
                try await SupabaseService.shared.updateProfile(userId: userUUID, profile: supaProfile)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.profile?.username = username
                    self.username = username
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                }
            }
        }
    }
}

class GamesViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSport: Game.SportType = .mlb
    
    func fetchGames(userId: String) {
        self.isLoading = true
        self.errorMessage = nil
        
        // Check if we have a development environment flag to use mock data
        if ProcessInfo.processInfo.environment["MOCK_DATA"] == "true" {
            print("Using mock data due to environment setting")
            let mockGames = selectedSport == .mlb ? 
                SportsService.shared.getMockMLBGames() : 
                SportsService.shared.getMockNBAGames()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.games = mockGames
                self.isLoading = false
            }
            return
        }
        
        // Use the SportsService to fetch real data for the selected sport
        if selectedSport == .mlb {
            SportsService.shared.fetchTodaysMLBSchedule { [weak self] fetchedGames in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let games = fetchedGames, !games.isEmpty {
                        print("Successfully fetched \(games.count) MLB games")
                        self.games = games
                    } else {
                        // If the API fails, fall back to mock data
                        print("Failed to fetch MLB data, using mock data instead")
                        self.games = SportsService.shared.getMockMLBGames()
                        self.errorMessage = "Couldn't fetch today's games. Using sample data."
                    }
                    self.isLoading = false
                }
            }
        } else {
            SportsService.shared.fetchTodaysNBASchedule { [weak self] fetchedGames in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let games = fetchedGames, !games.isEmpty {
                        print("Successfully fetched \(games.count) NBA games")
                        self.games = games
                    } else {
                        // If the API fails, fall back to mock data
                        print("Failed to fetch NBA data, using mock data instead")
                        self.games = SportsService.shared.getMockNBAGames()
                        self.errorMessage = "Couldn't fetch today's games. Using sample data."
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func vote(userId: String, gameId: Int, teamChoice: String) {
        // Placeholder implementation
        // In a real app, you would insert/update prediction in Supabase
        
        // Update local state
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.games.firstIndex(where: { $0.id == gameId }) {
                self.games[index].userVote = teamChoice
            }
        }
    }
}

class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var searchResults: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    
    func fetchFriends(userId: String) {
        self.isLoading = true
        
        // Placeholder implementation - in a real app, fetch from Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // Mock data
            self.friends = []
            self.isLoading = false
        }
    }
    
    func fetchFriendRequests(userId: String) {
        // Placeholder implementation - in a real app, fetch from Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // Mock data
            self.friendRequests = []
        }
    }
    
    func searchUsers(query: String, currentUserId: String) {
        if query.isEmpty {
            self.searchResults = []
            return
        }
        
        // Placeholder implementation - in a real app, search profiles in Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // Mock data
            self.searchResults = []
        }
    }
    
    func sendFriendRequest(senderId: String, receiverId: String) {
        // Placeholder implementation - in a real app, insert into friend_requests in Supabase
    }
    
    func acceptFriendRequest(senderId: String, receiverId: String) {
        // Placeholder implementation - in a real app, call a Supabase function
    }
    
    func declineFriendRequest(senderId: String, receiverId: String) {
        // Placeholder implementation - in a real app, delete from friend_requests in Supabase
    }
    
    func removeFriend(userId: String, friendId: String) {
        // Placeholder implementation - in a real app, delete from friends in Supabase
    }
}

class RankingsViewModel: ObservableObject {
    @Published var globalRankings: [UserRanking] = []
    @Published var friendRankings: [UserRanking] = []
    @Published var userRank: Int?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchGlobalRankings(currentUserId: String) {
        self.isLoading = true
        
        // Placeholder implementation - in a real app, fetch from Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // Mock data
            self.globalRankings = [
                UserRanking(id: "1", username: "Player1", hitRate: 92.5, rank: 1),
                UserRanking(id: "2", username: "Player2", hitRate: 87.3, rank: 2),
                UserRanking(id: currentUserId, username: "You", hitRate: 85.1, rank: 3)
            ]
            self.userRank = 3
            self.isLoading = false
        }
    }
    
    func fetchFriendRankings(userId: String) {
        self.isLoading = true
        
        // Placeholder implementation - in a real app, fetch from Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // Mock data
            self.friendRankings = [
                UserRanking(id: "1", username: "Friend1", hitRate: 82.5, rank: 1),
                UserRanking(id: userId, username: "You", hitRate: 75.0, rank: 2),
                UserRanking(id: "3", username: "Friend2", hitRate: 65.8, rank: 3)
            ]
            self.userRank = 2
            self.isLoading = false
        }
    }
}

// MARK: - Components
struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "baseball.fill")
                    .font(.system(size: 40))
                    .foregroundColor(HRTheme.gold)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                Text("LOADING...")
                    .font(HRTheme.Fonts.subtitle)
                    .foregroundColor(HRTheme.white)
                    .tracking(5)
            }
            .padding(30)
            .background(HRTheme.blue)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(HRTheme.gold, lineWidth: 3)
            )
        }
    }
}

struct AvatarView: View {
    var image: UIImage?
    var placeholder: String
    var size: CGFloat
    @State private var hoverScale: CGFloat = 1.0
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(HRTheme.goldBorder, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .scaleEffect(hoverScale)
                .onHover { hovering in
                    withAnimation(HRTheme.springAnimation) {
                        self.hoverScale = hovering ? 1.05 : 1.0
                    }
                }
        } else {
            ZStack {
                Circle()
                    .fill(HRTheme.blue.opacity(0.2))
                
                Text(placeholder.prefix(2).uppercased())
                    .font(.custom("ComicSansMS-Bold", size: size * 0.4))
                    .foregroundColor(HRTheme.blue)
            }
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(HRTheme.blueBorder, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(hoverScale)
            .onHover { hovering in
                withAnimation(HRTheme.springAnimation) {
                    self.hoverScale = hovering ? 1.05 : 1.0
                }
            }
        }
    }
}

struct GameCardView: View {
    var game: Game
    var onVote: (Int, String) -> Void
    @State private var cardOffset: CGFloat = 30
    @State private var cardOpacity: Double = 0
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(formatGameTime(game.startTime))
                    .font(HRTheme.Fonts.caption)
                    .foregroundColor(HRTheme.blue)
                    .padding(8)
                    .background(HRTheme.gold.opacity(0.3))
                    .cornerRadius(8)
                
                Spacer()
                
                if game.status == "scheduled" {
                    HStack(spacing: 6) {
                        Image(systemName: game.sportType == .mlb ? "baseball.fill" : "basketball.fill")
                            .foregroundColor(.white)
                        
                        Text("LIVE")
                            .font(HRTheme.Fonts.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HRTheme.red)
                    .cornerRadius(8)
                    .opacity(isAnimating ? 1 : 0.7)
                    .scaleEffect(isAnimating ? 1.05 : 1)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            VStack(spacing: 24) {
                // Away team
                TeamRowView(
                    teamAbbr: game.awayTeamAbbr ?? "",
                    teamName: game.awayTeam,
                    isSelected: game.userVote == "away",
                    onPick: { onVote(game.id, "away") },
                    isEnabled: game.status == "scheduled"
                )
                
                HStack {
                    Rectangle()
                        .fill(HRTheme.goldBorder)
                        .frame(height: 3)
                    Text("VS")
                        .font(HRTheme.Fonts.title)
                        .foregroundColor(HRTheme.blue)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(HRTheme.goldBorder)
                        .frame(height: 3)
                }
                .padding(.horizontal)
                
                // Home team
                TeamRowView(
                    teamAbbr: game.homeTeamAbbr ?? "",
                    teamName: game.homeTeam,
                    isSelected: game.userVote == "home",
                    onPick: { onVote(game.id, "home") },
                    isEnabled: game.status == "scheduled"
                )
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(HRTheme.blueBorder, lineWidth: 3)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.7)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }
    
    private func formatGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct TeamRowView: View {
    var teamAbbr: String
    var teamName: String
    var isSelected: Bool
    var onPick: () -> Void
    var isEnabled: Bool
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            HStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? HRTheme.gold : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(teamAbbr)
                        .font(.custom("ComicSansMS-Bold", size: 16))
                        .foregroundColor(isSelected ? HRTheme.blue : Color.gray)
                }
                
                Text(teamName)
                    .font(HRTheme.Fonts.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Button(action: onPick) {
                Text(isSelected ? "PICKED" : "PICK")
                    .font(.custom("ComicSansMS-Bold", size: 14))
                    .tracking(2)
                    .frame(width: 90)
                    .padding(.vertical, 10)
            }
            .buttonStyle(CPFMButtonStyle(
                bgColor: isSelected ? HRTheme.blue : HRTheme.white,
                borderColor: isSelected ? HRTheme.blueBorder : HRTheme.blueBorder,
                shadowColor: isSelected ? HRTheme.blueShadow : HRTheme.whiteShadow,
                textColor: isSelected ? .white : HRTheme.blue
            ))
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(isHovering && isEnabled ? 1.05 : 1)
            .onHover { hovering in
                withAnimation(HRTheme.springAnimation) {
                    isHovering = hovering && isEnabled
                }
            }
        }
    }
}

struct FriendsListView: View {
    var friends: [Friend]
    
    var body: some View {
        if friends.isEmpty {
            Text("No friends added yet")
                .font(HRTheme.Fonts.body)
                .foregroundColor(HRTheme.blue)
                .padding()
                .background(HRTheme.whiteBorder.opacity(0.5))
                .cornerRadius(12)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(friends) { friend in
                        VStack(alignment: .center) {
                            AvatarView(
                                image: nil,
                                placeholder: friend.username ?? "User",
                                size: 60
                            )
                            
                            ZStack {
                                Text("\(Int(friend.hitRate))%")
                                    .font(.custom("ComicSansMS-Bold", size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(HRTheme.blue)
                                    .cornerRadius(8)
                            }
                            
                            Text(friend.username ?? "User")
                                .font(HRTheme.Fonts.caption)
                                .foregroundColor(HRTheme.blue)
                                .lineLimit(1)
                                .frame(width: 75)
                        }
                        .frame(width: 75)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

struct RankingRowView: View {
    var ranking: UserRanking
    var isCurrentUser: Bool
    @State private var scaleAmount: CGFloat = 1.0
    
    var body: some View {
        HStack {
            Text("#\(ranking.rank)")
                .font(.custom("ComicSansMS-Bold", size: 18))
                .foregroundColor(isCurrentUser ? HRTheme.gold : HRTheme.blue)
                .frame(width: 40)
            
            AvatarView(
                image: nil,
                placeholder: ranking.username,
                size: 50
            )
            .padding(.horizontal, 12)
            
            VStack(alignment: .leading) {
                Text(ranking.username + (isCurrentUser ? " (You)" : ""))
                    .font(HRTheme.Fonts.body)
                    .foregroundColor(isCurrentUser ? HRTheme.gold : HRTheme.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(ranking.hitRate))%")
                    .font(.custom("ComicSansMS-Bold", size: 20))
                    .foregroundColor(isCurrentUser ? HRTheme.gold : HRTheme.blue)
                
                Text("↑ 3")
                    .font(HRTheme.Fonts.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isCurrentUser ? HRTheme.blue : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentUser ? HRTheme.gold : HRTheme.blueBorder, lineWidth: 3)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .scaleEffect(scaleAmount)
        .onAppear {
            if isCurrentUser {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scaleAmount = 1.02
                }
            }
        }
    }
}

// MARK: - Views
struct DashboardView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var gamesViewModel = GamesViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @State private var animateHeader = false
    
    var body: some View {
        NavigationView {
            ZStack {
                HRTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    VStack {
                        HStack {
                            AnimatedText(text: "HIT RIVALS", baseSize: 28)
                            
                            Spacer()
                            
                            BouncyEmoji(emoji: "⚾")
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Text("PLAY THE RIVALRY")
                            .font(.custom("ComicSansMS-Bold", size: 16))
                            .tracking(2)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(HRTheme.gold)
                            .foregroundColor(HRTheme.blue)
                            .offset(y: animateHeader ? 0 : -40)
                            .opacity(animateHeader ? 1 : 0)
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.6)) {
                                    animateHeader = true
                                }
                            }
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // User stats
                            HStack(spacing: 12) {
                                AvatarView(
                                    image: profileViewModel.avatarImage,
                                    placeholder: profileViewModel.profile?.username ?? "User",
                                    size: 60
                                )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profileViewModel.profile?.username ?? "User")
                                        .font(HRTheme.Fonts.subtitle)
                                    
                                    HStack(spacing: 4) {
                                        Text("\(Int(profileViewModel.hitRate))%")
                                            .font(.custom("ComicSansMS-Bold", size: 18))
                                            .foregroundColor(HRTheme.red)
                                        
                                        Text("HIT RATE")
                                            .font(.custom("ComicSansMS", size: 14))
                                            .foregroundColor(HRTheme.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("RANK")
                                        .font(.custom("ComicSansMS", size: 12))
                                        .foregroundColor(HRTheme.blue)
                                    
                                    Text("#\(profileViewModel.rank ?? 0)")
                                        .font(.custom("ComicSansMS-Bold", size: 24))
                                        .foregroundColor(HRTheme.gold)
                                }
                                .padding(12)
                                .background(HRTheme.blue)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(HRTheme.blueBorder, lineWidth: 3)
                                )
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(HRTheme.blueBorder, lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            // Friends section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("⭐ FRIENDS")
                                    .font(.custom("ComicSansMS-Bold", size: 16))
                                    .foregroundColor(HRTheme.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(HRTheme.gold)
                                    .cornerRadius(8)
                                
                                FriendsListView(friends: friendsViewModel.friends)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(HRTheme.blueBorder, lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            // Sport selector toggle
                            VStack(spacing: 12) {
                                Text("🏆 TODAY'S PICKS")
                                    .font(.custom("ComicSansMS-Bold", size: 20))
                                    .foregroundColor(HRTheme.blue)
                                
                                HStack(spacing: 0) {
                                    Button(action: {
                                        if gamesViewModel.selectedSport != .mlb {
                                            gamesViewModel.selectedSport = .mlb
                                            Task {
                                                if let user = try? await SupabaseService.shared.getUser() {
                                                    gamesViewModel.fetchGames(userId: user.id.uuidString)
                                                }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "baseball.fill")
                                            Text("MLB")
                                                .font(.custom("ComicSansMS-Bold", size: 16))
                                        }
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(gamesViewModel.selectedSport == .mlb ? .white : HRTheme.blue)
                                        .background(gamesViewModel.selectedSport == .mlb ? HRTheme.blue : HRTheme.gold.opacity(0.3))
                                        .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(HRTheme.blueBorder, lineWidth: 3)
                                                .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                                        )
                                    }
                                    
                                    Button(action: {
                                        if gamesViewModel.selectedSport != .nba {
                                            gamesViewModel.selectedSport = .nba
                                            Task {
                                                if let user = try? await SupabaseService.shared.getUser() {
                                                    gamesViewModel.fetchGames(userId: user.id.uuidString)
                                                }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "basketball.fill")
                                            Text("NBA")
                                                .font(.custom("ComicSansMS-Bold", size: 16))
                                        }
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(gamesViewModel.selectedSport == .nba ? .white : HRTheme.blue)
                                        .background(gamesViewModel.selectedSport == .nba ? HRTheme.blue : HRTheme.gold.opacity(0.3))
                                        .cornerRadius(12, corners: [.topRight, .bottomRight])
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(HRTheme.blueBorder, lineWidth: 3)
                                                .cornerRadius(12, corners: [.topRight, .bottomRight])
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Games list
                            if gamesViewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(2)
                                        .padding(40)
                                    Spacer()
                                }
                            } else if gamesViewModel.games.isEmpty {
                                VStack {
                                    Image(systemName: gamesViewModel.selectedSport == .mlb ? "baseball" : "basketball")
                                        .font(.system(size: 40))
                                        .foregroundColor(HRTheme.blue)
                                        .padding()
                                    
                                    Text("NO GAMES TODAY")
                                        .font(.custom("ComicSansMS-Bold", size: 18))
                                        .foregroundColor(HRTheme.blue)
                                    
                                    Text("Check back later!")
                                        .font(HRTheme.Fonts.body)
                                        .foregroundColor(HRTheme.blue.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                .padding(30)
                                .background(Color.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(HRTheme.blueBorder, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 20) {
                                    ForEach(gamesViewModel.games) { game in
                                        GameCardView(game: game) { gameId, teamChoice in
                                            Task {
                                                if let user = try? await SupabaseService.shared.getUser() {
                                                    gamesViewModel.vote(
                                                        userId: user.id.uuidString,
                                                        gameId: gameId,
                                                        teamChoice: teamChoice
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
                
                if profileViewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                if let user = try? await SupabaseService.shared.getUser() {
                    profileViewModel.getProfile(userId: user.id.uuidString)
                    gamesViewModel.fetchGames(userId: user.id.uuidString)
                    friendsViewModel.fetchFriends(userId: user.id.uuidString)
                }
            }
        }
    }
}

struct RankingsView: View {
    @StateObject var rankingsViewModel = RankingsViewModel()
    @State private var selectedTab = 0 // 0 = global, 1 = friends
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        Button(action: {
                            selectedTab = 0
                            Task {
                                if let user = try? await SupabaseService.shared.getUser() {
                                    rankingsViewModel.fetchGlobalRankings(currentUserId: user.id.uuidString)
                                }
                            }
                        }) {
                            Text("Global")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(selectedTab == 0 ? .blue : .gray)
                        }
                        .background(
                            VStack {
                                Spacer()
                                if selectedTab == 0 {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: 2)
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 2)
                                }
                            }
                        )
                        
                        Button(action: {
                            selectedTab = 1
                            Task {
                                if let user = try? await SupabaseService.shared.getUser() {
                                    rankingsViewModel.fetchFriendRankings(userId: user.id.uuidString)
                                }
                            }
                        }) {
                            Text("Friends")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(selectedTab == 1 ? .blue : .gray)
                        }
                        .background(
                            VStack {
                                Spacer()
                                if selectedTab == 1 {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: 2)
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 2)
                                }
                            }
                        )
                    }
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if rankingsViewModel.isLoading {
                                ProgressView()
                                    .padding(.top, 40)
                            } else {
                                let rankings = selectedTab == 0 ? rankingsViewModel.globalRankings : rankingsViewModel.friendRankings
                                
                                if rankings.isEmpty {
                                    Text(selectedTab == 0 ? "No rankings available yet." : "No friends added yet.")
                                        .foregroundColor(.gray)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        .padding(.top, 20)
                                } else {
                                    ForEach(rankings) { ranking in
                                        // Simplified for now - determine current user status
                                        let isCurrentUser = Task {
                                            if let user = try? await SupabaseService.shared.getUser() {
                                                return ranking.id == user.id.uuidString
                                            }
                                            return false
                                        }
                                        
                                        RankingRowView(
                                            ranking: ranking,
                                            isCurrentUser: false // Simplify for now
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .padding(.bottom, 20) // Extra space at the bottom
                    }
                }
            }
            .navigationTitle("🏆 Rankings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                if let user = try? await SupabaseService.shared.getUser() {
                    if selectedTab == 0 {
                        rankingsViewModel.fetchGlobalRankings(currentUserId: user.id.uuidString)
                    } else {
                        rankingsViewModel.fetchFriendRankings(userId: user.id.uuidString)
                    }
                }
            }
        }
    }
}

struct FriendsView: View {
    @StateObject var friendsViewModel = FriendsViewModel()
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Search
                        HStack {
                            TextField("Search for friends...", text: $searchQuery)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button(action: {
                                Task {
                                    if let user = try? await SupabaseService.shared.getUser() {
                                        friendsViewModel.searchUsers(
                                            query: searchQuery,
                                            currentUserId: user.id.uuidString
                                        )
                                    }
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Search results
                        if !friendsViewModel.searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SEARCH RESULTS")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                ForEach(friendsViewModel.searchResults) { user in
                                    HStack {
                                        AvatarView(
                                            image: nil,
                                            placeholder: user.username ?? "User",
                                            size: 40
                                        )
                                        .padding(.trailing, 8)
                                        
                                        Text(user.username ?? "User")
                                            .font(.system(size: 16))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            Task {
                                                if let currentUser = try? await SupabaseService.shared.getUser() {
                                                    friendsViewModel.sendFriendRequest(
                                                        senderId: currentUser.id.uuidString,
                                                        receiverId: user.id
                                                    )
                                                }
                                            }
                                        }) {
                                            Text("Add")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .cornerRadius(6)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                }
                            }
                        }
                        
                        // Friend requests
                        if !friendsViewModel.friendRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FRIEND REQUESTS (\(friendsViewModel.friendRequests.count))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                ForEach(friendsViewModel.friendRequests, id: \.senderId) { request in
                                    HStack {
                                        AvatarView(
                                            image: nil,
                                            placeholder: request.username ?? "User",
                                            size: 40
                                        )
                                        .padding(.trailing, 8)
                                        
                                        Text(request.username ?? "User")
                                            .font(.system(size: 16))
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                Task {
                                                    if let currentUser = try? await SupabaseService.shared.getUser() {
                                                        friendsViewModel.acceptFriendRequest(
                                                            senderId: request.senderId,
                                                            receiverId: currentUser.id.uuidString
                                                        )
                                                    }
                                                }
                                            }) {
                                                Text("Accept")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.green)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Button(action: {
                                                Task {
                                                    if let currentUser = try? await SupabaseService.shared.getUser() {
                                                        friendsViewModel.declineFriendRequest(
                                                            senderId: request.senderId,
                                                            receiverId: currentUser.id.uuidString
                                                        )
                                                    }
                                                }
                                            }) {
                                                Text("Decline")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                }
                            }
                        }
                        
                        // Friends list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR FRIENDS (\(friendsViewModel.friends.count))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            if friendsViewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                            } else if friendsViewModel.friends.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No friends added yet.")
                                        .foregroundColor(.gray)
                                    
                                    Text("Search for users to add friends.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            } else {
                                ForEach(friendsViewModel.friends) { friend in
                                    HStack {
                                        AvatarView(
                                            image: nil,
                                            placeholder: friend.username ?? "User",
                                            size: 40
                                        )
                                        .padding(.trailing, 8)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(friend.username ?? "User")
                                                .font(.system(size: 16))
                                            
                                            Text("\(Int(friend.hitRate))% Hit Rate")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Button(role: .destructive, action: {
                                                Task {
                                                    if let currentUser = try? await SupabaseService.shared.getUser() {
                                                        friendsViewModel.removeFriend(
                                                            userId: currentUser.id.uuidString,
                                                            friendId: friend.friendId
                                                        )
                                                    }
                                                }
                                            }) {
                                                Label("Remove Friend", systemImage: "person.badge.minus")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .foregroundColor(.gray)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 20) // Extra space at the bottom
                }
            }
            .navigationTitle("👥 Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                if let user = try? await SupabaseService.shared.getUser() {
                    friendsViewModel.fetchFriends(userId: user.id.uuidString)
                    friendsViewModel.fetchFriendRequests(userId: user.id.uuidString)
                }
            }
        }
    }
}

struct ProfileView: View {
    @StateObject private var appModel = AppModel.shared
    @StateObject var profileViewModel = ProfileViewModel()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingLogout = false
    @State private var userId: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // User info card
                        VStack(spacing: 16) {
                            // Avatar with edit button
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(
                                    image: selectedImage ?? profileViewModel.avatarImage,
                                    placeholder: profileViewModel.username,
                                    size: 96
                                )
                                
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                                .offset(x: 8, y: 8)
                            }
                            .padding(.top, 8)
                            
                            Text(profileViewModel.username.isEmpty ? "User" : profileViewModel.username)
                                .font(.system(size: 20, weight: .bold))
                            
                            Text("Hit Rate: \(Int(profileViewModel.hitRate))%")
                                .foregroundColor(.gray)
                            
                            if let rank = profileViewModel.rank {
                                Text("Rank: #\(rank) of 1,245")
                                    .foregroundColor(.gray)
                            }
                            
                            if let userId = userId {
                                Text("User ID: \(userId)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Edit profile
                        VStack(alignment: .leading, spacing: 16) {
                            Text("📝 Edit Profile")
                                .font(.system(size: 18, weight: .bold))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .foregroundColor(.gray)
                                
                                TextField("Username", text: $profileViewModel.username)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                Task {
                                    if let user = try? await SupabaseService.shared.getUser() {
                                        profileViewModel.updateProfile(
                                            userId: user.id.uuidString,
                                            username: profileViewModel.username
                                        )
                                        
                                        if let selectedImage = selectedImage {
                                            profileViewModel.uploadAvatar(
                                                image: selectedImage,
                                                userId: user.id.uuidString
                                            )
                                        }
                                    }
                                }
                            }) {
                                Text("Save Changes")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Account security
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🔒 Account Security")
                                .font(.system(size: 18, weight: .bold))
                            
                            Button(action: {
                                // Reset password logic
                            }) {
                                Text("Change Password")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // About
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ℹ️ About HitRivals")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("HitRivals is a sports prediction game where you can compete with friends to see who has the best hit rate.")
                                .foregroundColor(.gray)
                            
                            Text("Version 1.0.0")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Sign out / Delete account
                        VStack(spacing: 12) {
                            Button(action: {
                                showingLogout = true
                            }) {
                                Text("📤 Sign Out")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // Delete account logic
                            }) {
                                Text("❌ Delete Account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 20) // Extra space at the bottom
                    }
                    .padding()
                }
                
                if profileViewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationTitle("👤 Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                await loadUserData()
                
                if let user = try? await SupabaseService.shared.getUser() {
                    profileViewModel.getProfile(userId: user.id.uuidString)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("Logout", isPresented: $showingLogout) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    await signOut()
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private func loadUserData() async {
        do {
            if let user = try await SupabaseService.shared.getUser() {
                DispatchQueue.main.async {
                    self.userId = user.id.uuidString
                    print("Loaded user ID: \(user.id.uuidString)")
                }
            } else {
                print("No user found")
            }
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    private func signOut() async {
        do {
            try await appModel.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var appModel = AppModel.shared
    @State private var selectedTab = 0
    @State private var tabBarOffset: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .environmentObject(appModel)
                    .tag(0)
                
                RankingsView()
                    .tag(1)
                
                FriendsView()
                    .tag(2)
                
                ProfileView()
                    .tag(3)
            }
            .accentColor(HRTheme.blue)
            .onAppear {
                // Set font registration
                UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(HRTheme.blue)]
                UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(HRTheme.blue)]
                
                // Remove TabBar default styling
                UITabBar.appearance().backgroundImage = UIImage()
                UITabBar.appearance().shadowImage = UIImage()
                UITabBar.appearance().backgroundColor = .clear
                UITabBar.appearance().barTintColor = .clear
                
                // Animate tab bar
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    tabBarOffset = 0
                }
            }
            
            // Custom TabBar
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tabIcon(for: index))
                                .font(.system(size: 24))
                            
                            Text(tabTitle(for: index))
                                .font(.custom("ComicSansMS", size: 12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedTab == index ? HRTheme.gold : .white)
                        .background(
                            selectedTab == index ?
                            HRTheme.blue.opacity(0.8) :
                            HRTheme.blue
                        )
                        .contentShape(Rectangle())
                    }
                }
            }
            .background(HRTheme.blue)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(HRTheme.gold, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .offset(y: tabBarOffset)
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "trophy.fill"
        case 2: return "person.2.fill"
        case 3: return "person.crop.circle.fill"
        default: return "questionmark"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "HOME"
        case 1: return "RANKS"
        case 2: return "FRIENDS"
        case 3: return "PROFILE"
        default: return ""
        }
    }
}

// MARK: - SwiftUI Preview
#Preview {
    ContentView()
}

// Add extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
