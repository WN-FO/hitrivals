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
    @Published var selectedDate = Date()
    
    func fetchGames(userId: String) {
        self.isLoading = true
        self.errorMessage = nil
        
        // Check if we have a development environment flag to use mock data
        if ProcessInfo.processInfo.environment["MOCK_MLB_DATA"] == "true" {
            print("Using mock MLB data due to environment setting")
            let mockGames = MLBService.shared.getMockMLBGames()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.games = mockGames
                self.isLoading = false
            }
            return
        }
        
        // Use the new MLBService to fetch real data for the selected date
        MLBService.shared.fetchMLBScheduleForDate(date: selectedDate) { [weak self] fetchedGames in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let games = fetchedGames, !games.isEmpty {
                    print("Successfully fetched \(games.count) MLB games for the selected date")
                    self.games = games
                } else {
                    // If the API fails, fall back to mock data
                    print("Failed to fetch MLB data or no games scheduled, using mock data instead")
                    self.games = MLBService.shared.getMockMLBGames()
                    self.errorMessage = "Couldn't fetch games for the selected date. Using sample data."
                }
                self.isLoading = false
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
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
                .ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(2)
                .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1.0))))
        }
    }
}

struct AvatarView: View {
    var image: UIImage?
    var placeholder: String
    var size: CGFloat
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                
                Text(placeholder.prefix(2).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.gray)
            }
            .frame(width: size, height: size)
        }
    }
}

struct GameCardView: View {
    var game: Game
    var onVote: (Int, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(formatGameTime(game.startTime))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            VStack(spacing: 16) {
                // Away team
                HStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Text(game.awayTeamAbbr ?? "")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        
                        Text(game.awayTeam)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onVote(game.id, "away")
                    }) {
                        Text(game.userVote == "away" ? "Picked" : "Pick")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .background(game.userVote == "away" ? Color.blue : Color.gray.opacity(0.1))
                            .foregroundColor(game.userVote == "away" ? .white : .black)
                            .cornerRadius(8)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(game.status != "scheduled")
                }
                
                Divider()
                
                // Home team
                HStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Text(game.homeTeamAbbr ?? "")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        
                        Text(game.homeTeam)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onVote(game.id, "home")
                    }) {
                        Text(game.userVote == "home" ? "Picked" : "Pick")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .background(game.userVote == "home" ? Color.blue : Color.gray.opacity(0.1))
                            .foregroundColor(game.userVote == "home" ? .white : .black)
                            .cornerRadius(8)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(game.status != "scheduled")
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct FriendsListView: View {
    var friends: [Friend]
    
    var body: some View {
        if friends.isEmpty {
            Text("No friends added yet")
                .foregroundColor(.gray)
                .padding()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(friends) { friend in
                        VStack(alignment: .center) {
                            AvatarView(
                                image: nil, // You'd need to load these images
                                placeholder: friend.username ?? "User",
                                size: 48
                            )
                            
                            Text("\(Int(friend.hitRate))%")
                                .font(.system(size: 12, weight: .bold))
                            
                            Text(friend.username ?? "User")
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .frame(width: 64)
                        }
                        .frame(width: 64)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct RankingRowView: View {
    var ranking: UserRanking
    var isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Text("#\(ranking.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 32)
            
            AvatarView(
                image: nil, // You'd need to load these images
                placeholder: ranking.username,
                size: 48
            )
            .padding(.horizontal, 12)
            
            VStack(alignment: .leading) {
                Text(ranking.username + (isCurrentUser ? " (You)" : ""))
                    .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(ranking.hitRate))%")
                    .font(.system(size: 18, weight: .bold))
                
                Text("↑ 3")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Views
struct DashboardView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var gamesViewModel = GamesViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header included in NavigationView
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // User stats
                            HStack(spacing: 12) {
                                AvatarView(
                                    image: profileViewModel.avatarImage,
                                    placeholder: profileViewModel.profile?.username ?? "User",
                                    size: 48
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profileViewModel.profile?.username ?? "User")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    HStack(spacing: 2) {
                                        Text("\(Int(profileViewModel.hitRate))%")
                                            .font(.system(size: 14, weight: .bold))
                                        
                                        Text("Hit Rate")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.top)
                            
                            // Friends section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FRIENDS")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                FriendsListView(friends: friendsViewModel.friends)
                            }
                            
                            // Date selector
                            HStack {
                                Text(formatDate(gamesViewModel.selectedDate))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Button(action: {
                                    showDatePicker.toggle()
                                }) {
                                    Image(systemName: "calendar")
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                            
                            if showDatePicker {
                                DatePicker(
                                    "",
                                    selection: $gamesViewModel.selectedDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .onChange(of: gamesViewModel.selectedDate) { _, newDate in
                                    showDatePicker = false
                                    print("Date changed to: \(formatDate(newDate))")
                                    
                                    // Fetch games for the newly selected date
                                    Task {
                                        if let user = try? await SupabaseService.shared.getUser() {
                                            gamesViewModel.fetchGames(userId: user.id.uuidString)
                                        }
                                    }
                                }
                            }
                            
                            // Games list
                            if gamesViewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding(.top, 40)
                            } else if gamesViewModel.games.isEmpty {
                                VStack {
                                    Text("No games scheduled for this date.")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            } else {
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
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20) // Extra space at the bottom
                    }
                }
                
                if profileViewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationTitle("⚾ Today's Games")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: date).uppercased()
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(appModel)
                .tag(0)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            RankingsView()
                .tag(1)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Rankings")
                }
            
            FriendsView()
                .tag(2)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            
            ProfileView()
                .tag(3)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - SwiftUI Preview
#Preview {
    ContentView()
}
