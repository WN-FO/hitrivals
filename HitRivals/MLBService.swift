import Foundation

/// Service for fetching MLB game data from Tank01 API
class MLBService {
    static let shared = MLBService()
    
    private let baseURL = "https://tank01-mlb-live-in-game-real-time-statistics.p.rapidapi.com"
    private let apiKey = "bc4fa015f9msh97c01d2babd5043p1cda77jsnea2e8fd2690f"
    
    private init() {}
    
    /// Fetch today's MLB schedule
    func fetchTodaysMLBSchedule(completion: @escaping ([Game]?) -> Void) {
        fetchMLBScheduleForDate(date: Date(), completion: completion)
    }
    
    /// Fetch MLB schedule for a specific date
    func fetchMLBScheduleForDate(date: Date, completion: @escaping ([Game]?) -> Void) {
        fetchMLBSchedule(date: date, attempts: 3, completion: completion)
    }
    
    /// Fetch MLB schedule with retry mechanism
    private func fetchMLBSchedule(date: Date, attempts: Int, completion: @escaping ([Game]?) -> Void) {
        guard attempts > 0 else {
            print("No more retry attempts left for MLB API")
            completion(nil)
            return
        }
        
        // Get the date in YYYYMMDD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        
        // API endpoint to get games for the date
        let endpoint = "/getMLBGamesForDate?gameDate=\(dateString)"
        
        print("Fetching MLB games for date: \(dateString)")
        
        // Construct the URL
        guard let url = URL(string: baseURL + endpoint) else {
            print("Error: invalid URL")
            completion(nil)
            return
        }
        
        // Create the request with headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue("tank01-mlb-live-in-game-real-time-statistics.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for HTTP response status code
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("HTTP Error: \(httpResponse.statusCode)")
                
                // Wait and retry with exponential backoff
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchMLBSchedule(date: date, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            // Handle errors
            if let error = error {
                print("Error fetching MLB data: \(error)")
                
                // Wait and retry
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchMLBSchedule(date: date, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                print("No data returned from MLB API")
                
                // Wait and retry
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchMLBSchedule(date: date, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            do {
                // For debugging: print the response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("MLB API Response (first 200 chars): \(String(jsonString.prefix(200)))")
                }
                
                // Parse the JSON response
                let decoder = JSONDecoder()
                
                // First try to parse as the expected structure
                do {
                    let apiResponse = try decoder.decode(MLBApiResponse.self, from: data)
                    let games = self.convertApiGamesToGames(apiResponse.body)
                    completion(games)
                    return
                } catch {
                    print("Could not decode as MLBApiResponse: \(error)")
                    
                    // Try to parse as a direct array of games
                    do {
                        let apiGames = try decoder.decode([MLBApiGame].self, from: data)
                        let games = self.convertApiGamesToGames(apiGames)
                        completion(games)
                        return
                    } catch {
                        print("Could not decode as [MLBApiGame] either: \(error)")
                        
                        // One more attempt with a different structure
                        do {
                            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let bodyData = responseDict?["body"] as? [[String: Any]] {
                                let bodyJsonData = try JSONSerialization.data(withJSONObject: bodyData)
                                let apiGames = try decoder.decode([MLBApiGame].self, from: bodyJsonData)
                                let games = self.convertApiGamesToGames(apiGames)
                                completion(games)
                                return
                            }
                        } catch {
                            print("All parsing attempts failed: \(error)")
                            
                            // Wait and retry
                            if attempts > 1 {
                                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                    self.fetchMLBSchedule(date: date, attempts: attempts - 1, completion: completion)
                                }
                            } else {
                                completion(nil)
                            }
                        }
                    }
                }
            } catch {
                print("Error handling MLB data: \(error)")
                
                // Wait and retry
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchMLBSchedule(date: date, attempts: attempts - 1, completion: completion)
                }
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    /// Convert API games to app Game model
    private func convertApiGamesToGames(_ apiGames: [MLBApiGame]) -> [Game] {
        var games = [Game]()
        
        for apiGame in apiGames {
            // Determine the start time
            var startTime = Date()
            
            // First try to use the epoch time if available
            if let epochTimeString = apiGame.gameTime_epoch,
               let epochTime = Double(epochTimeString) {
                startTime = Date(timeIntervalSince1970: epochTime)
            }
            // Otherwise parse the date and time manually
            else if let date = parseGameDateTime(date: apiGame.gameDate, time: apiGame.gameTime) {
                startTime = date
            }
            
            // Create a unique game ID by combining aspects of the gameID string
            // Format is typically "20250503_LAD@ATL"
            let gameId: Int
            let components = apiGame.gameID.split(separator: "_")
            if components.count >= 2 {
                // Use date and a hash of the teams to create a unique ID
                let dateComponent = components[0]
                let teamsComponent = components[1]
                
                // Create a hash from the teams string
                let teamsHash = abs(teamsComponent.hashValue % 10000)
                
                // Combine with a unique ID using last 4 digits of date + teams hash
                if let dateInt = Int(dateComponent.suffix(4)) {
                    gameId = (dateInt * 10000) + teamsHash
                } else {
                    // Fallback to just the hash if date parsing fails
                    gameId = teamsHash + Int.random(in: 1000...9999)
                }
            } else {
                // Fallback to a hash of the entire gameID string if the format is unexpected
                gameId = abs(apiGame.gameID.hashValue % 1000000)
            }
            
            print("Generated game ID: \(gameId) from gameID: \(apiGame.gameID)")
            
            let game = Game(
                id: gameId,
                homeTeam: getFullTeamName(apiGame.home),
                awayTeam: getFullTeamName(apiGame.away),
                homeTeamAbbr: apiGame.home,
                awayTeamAbbr: apiGame.away,
                startTime: startTime,
                status: "scheduled"  // Default status
            )
            
            games.append(game)
        }
        
        return games
    }
    
    /// Parse game date and time from the API format
    private func parseGameDateTime(date: String, time: String) -> Date? {
        // API date format is "YYYYMMDD" and time is like "7:10p"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        guard let gameDate = dateFormatter.date(from: date) else {
            return nil
        }
        
        // Parse the time which is in format like "7:10p" or "10:15a"
        let calendar = Calendar.current
        var hour = 0
        var minute = 0
        
        // Extract hour and minute from time string
        let timeParts = time.lowercased().replacingOccurrences(of: "p", with: "").replacingOccurrences(of: "a", with: "").split(separator: ":")
        if timeParts.count == 2, 
           let h = Int(timeParts[0]),
           let m = Int(timeParts[1]) {
            hour = h
            minute = m
            
            // Adjust for PM
            if time.lowercased().contains("p") && hour < 12 {
                hour += 12
            }
        }
        
        // Create the final date with the correct time
        var components = calendar.dateComponents([.year, .month, .day], from: gameDate)
        components.hour = hour
        components.minute = minute
        
        return calendar.date(from: components)
    }
    
    /// Get full team name from abbreviation
    private func getFullTeamName(_ abbreviation: String) -> String {
        let teamNames: [String: String] = [
            "ARI": "Arizona Diamondbacks",
            "ATL": "Atlanta Braves",
            "BAL": "Baltimore Orioles",
            "BOS": "Boston Red Sox",
            "CHC": "Chicago Cubs",
            "CWS": "Chicago White Sox",
            "CIN": "Cincinnati Reds",
            "CLE": "Cleveland Guardians",
            "COL": "Colorado Rockies",
            "DET": "Detroit Tigers",
            "HOU": "Houston Astros",
            "KC": "Kansas City Royals",
            "LAA": "Los Angeles Angels",
            "LAD": "Los Angeles Dodgers",
            "MIA": "Miami Marlins",
            "MIL": "Milwaukee Brewers",
            "MIN": "Minnesota Twins",
            "NYM": "New York Mets",
            "NYY": "New York Yankees",
            "OAK": "Oakland Athletics",
            "PHI": "Philadelphia Phillies",
            "PIT": "Pittsburgh Pirates",
            "SD": "San Diego Padres",
            "SF": "San Francisco Giants",
            "SEA": "Seattle Mariners",
            "STL": "St. Louis Cardinals",
            "TB": "Tampa Bay Rays",
            "TEX": "Texas Rangers",
            "TOR": "Toronto Blue Jays",
            "WSH": "Washington Nationals"
        ]
        
        return teamNames[abbreviation] ?? abbreviation
    }
    
    // MARK: - Mock Data
    
    /// Get mock MLB games for testing
    func getMockMLBGames() -> [Game] {
        return [
            Game(
                id: 1,
                homeTeam: "New York Yankees",
                awayTeam: "Boston Red Sox",
                homeTeamAbbr: "NYY",
                awayTeamAbbr: "BOS",
                startTime: Calendar.current.date(bySettingHour: 19, minute: 5, second: 0, of: Date()) ?? Date(),
                status: "scheduled"
            ),
            Game(
                id: 2,
                homeTeam: "St. Louis Cardinals",
                awayTeam: "Chicago Cubs",
                homeTeamAbbr: "STL",
                awayTeamAbbr: "CHC",
                startTime: Calendar.current.date(bySettingHour: 20, minute: 15, second: 0, of: Date()) ?? Date(),
                status: "scheduled"
            ),
            Game(
                id: 3,
                homeTeam: "Los Angeles Dodgers",
                awayTeam: "San Francisco Giants",
                homeTeamAbbr: "LAD",
                awayTeamAbbr: "SF",
                startTime: Calendar.current.date(bySettingHour: 22, minute: 10, second: 0, of: Date()) ?? Date(),
                status: "scheduled"
            )
        ]
    }
}

// MARK: - API Response Models

struct MLBApiResponse: Codable {
    let statusCode: Int
    let body: [MLBApiGame]
}

struct MLBApiGame: Codable {
    let gameID: String
    let gameType: String
    let away: String
    let home: String
    let gameDate: String
    let gameTime: String
    let gameTime_epoch: String?
    let teamIDHome: String
    let teamIDAway: String
    
    // Optional fields
    let probableStartingPitchers: MLBPitchers?
    let probableStartingLineups: MLBLineups?
    
    struct MLBPitchers: Codable {
        let away: String?
        let home: String?
    }
    
    struct MLBLineups: Codable {
        let away: [MLBBatter]?
        let home: [MLBBatter]?
        
        struct MLBBatter: Codable {
            let battingOrder: String
            let playerID: String
        }
    }
} 