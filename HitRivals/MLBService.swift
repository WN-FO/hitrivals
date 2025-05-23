import Foundation

/// Service for fetching MLB and NBA game data from Tank01 API
class SportsService {
    static let shared = SportsService()
    
    // Use the same SportType enum as defined in the Game model
    enum SportType {
        case mlb
        case nba
        
        // Convert to Game.SportType
        func toGameSportType() -> Game.SportType {
            switch self {
            case .mlb:
                return .mlb
            case .nba:
                return .nba
            }
        }
        
        // Create from Game.SportType
        static func from(gameSportType: Game.SportType) -> SportType {
            switch gameSportType {
            case .mlb:
                return .mlb
            case .nba:
                return .nba
            }
        }
    }
    
    private let mlbBaseURL = "https://tank01-mlb-live-in-game-real-time-statistics.p.rapidapi.com"
    private let nbaBaseURL = "https://tank01-fantasy-stats.p.rapidapi.com"
    private let apiKey = "bc4fa015f9msh97c01d2babd5043p1cda77jsnea2e8fd2690f"
    
    private init() {}
    
    /// Fetch today's MLB schedule
    func fetchTodaysMLBSchedule(completion: @escaping ([Game]?) -> Void) {
        fetchMLBSchedule(date: Date(), attempts: 3, completion: completion)
    }
    
    /// Fetch today's NBA schedule
    func fetchTodaysNBASchedule(completion: @escaping ([Game]?) -> Void) {
        fetchNBASchedule(date: Date(), attempts: 3, completion: completion)
    }
    
    /// Fetch live score for an MLB game
    func fetchMLBLiveScore(gameID: String, completion: @escaping (Game?) -> Void) {
        let endpoint = "/getMLBLineScore?gameID=\(gameID)"
        
        print("Fetching MLB live score for game: \(gameID)")
        
        // Construct the URL
        guard let url = URL(string: mlbBaseURL + endpoint) else {
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
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                print("Error fetching MLB live score: \(error)")
                completion(nil)
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                print("No data returned from MLB live score API")
                completion(nil)
                return
            }
            
            do {
                // Parse the JSON response
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(MLBLiveScoreResponse.self, from: data)
                
                // Extract game info
                let gameStatus = apiResponse.body.gameStatus
                let currentInning = apiResponse.body.currentInning
                let homeTeamAbbr = apiResponse.body.home
                let awayTeamAbbr = apiResponse.body.away
                
                // Extract scores
                let homeScore = Int(apiResponse.body.lineScore.home.R) ?? 0
                let awayScore = Int(apiResponse.body.lineScore.away.R) ?? 0
                
                // Extract scores by inning
                let homeScoresByInning = apiResponse.body.lineScore.home.scoresByInning
                let awayScoresByInning = apiResponse.body.lineScore.away.scoresByInning
                
                // Get the standard game components
                var components = gameID.split(separator: "_")
                if components.count >= 2 {
                    let dateComponent = components[0]
                    let teamsComponent = components[1]
                    
                    // Create a unique integer id from the string id
                    let teamsHash = abs(teamsComponent.hashValue % 10000)
                    let gameIdInt: Int
                    if let dateInt = Int(dateComponent.suffix(4)) {
                        gameIdInt = (dateInt * 10000) + teamsHash
                    } else {
                        gameIdInt = teamsHash + Int.random(in: 1000...9999)
                    }
                    
                    // Create a game object with the score information
                    let game = Game(
                        id: gameIdInt,
                        homeTeam: self.getMLBFullTeamName(homeTeamAbbr),
                        awayTeam: self.getMLBFullTeamName(awayTeamAbbr),
                        homeTeamAbbr: homeTeamAbbr,
                        awayTeamAbbr: awayTeamAbbr,
                        startTime: Date(),  // We don't know the exact start time here
                        status: gameStatus.lowercased(),
                        sportType: .mlb,
                        homeScore: homeScore,
                        awayScore: awayScore,
                        currentInningOrQuarter: currentInning,
                        homeScoreByPeriod: homeScoresByInning,
                        awayScoreByPeriod: awayScoresByInning
                    )
                    
                    completion(game)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing MLB live score data: \(error)")
                completion(nil)
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    /// Fetch live score for an NBA game
    func fetchNBALiveScore(gameID: String, completion: @escaping (Game?) -> Void) {
        let endpoint = "/getNBABoxScore?gameID=\(gameID)&fantasyPoints=true&pts=1&stl=3&blk=3&reb=1.25&ast=1.5&TOV=-1&mins=0&doubleDouble=0&tripleDouble=0&quadDouble=0"
        
        print("Fetching NBA live score for game: \(gameID)")
        
        // Construct the URL
        guard let url = URL(string: nbaBaseURL + endpoint) else {
            print("Error: invalid URL")
            completion(nil)
            return
        }
        
        // Create the request with headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue("tank01-fantasy-stats.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                print("Error fetching NBA live score: \(error)")
                completion(nil)
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                print("No data returned from NBA live score API")
                completion(nil)
                return
            }
            
            do {
                // Parse the JSON response
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(NBABoxScoreResponse.self, from: data)
                
                // Extract game info
                let gameStatus = apiResponse.body.gameStatus
                let currentPeriod = apiResponse.body.gameClock
                let homeTeamAbbr = apiResponse.body.home
                let awayTeamAbbr = apiResponse.body.away
                
                // Extract scores
                let homeScore = Int(apiResponse.body.homePts) ?? 0
                let awayScore = Int(apiResponse.body.awayPts) ?? 0
                
                // Extract scores by quarter
                var homeScoresByPeriod: [String: String] = [:]
                var awayScoresByPeriod: [String: String] = [:]
                
                if let homeLine = apiResponse.body.lineScore.CLE,
                   let awayLine = apiResponse.body.lineScore.SA {
                    homeScoresByPeriod = [
                        "1": homeLine.Q1 ?? "0",
                        "2": homeLine.Q2 ?? "0",
                        "3": homeLine.Q3 ?? "0",
                        "4": homeLine.Q4 ?? "0"
                    ]
                    
                    awayScoresByPeriod = [
                        "1": awayLine.Q1 ?? "0",
                        "2": awayLine.Q2 ?? "0",
                        "3": awayLine.Q3 ?? "0",
                        "4": awayLine.Q4 ?? "0"
                    ]
                }
                
                // Get the standard game components
                var components = gameID.split(separator: "_")
                if components.count >= 2 {
                    let dateComponent = components[0]
                    let teamsComponent = components[1]
                    
                    // Create a unique integer id from the string id
                    let teamsHash = abs(teamsComponent.hashValue % 10000)
                    let gameIdInt: Int
                    if let dateInt = Int(dateComponent.suffix(4)) {
                        gameIdInt = (dateInt * 10000) + teamsHash + 5000000 // Add offset to avoid MLB ID collisions
                    } else {
                        gameIdInt = teamsHash + 5000000 + Int.random(in: 1000...9999)
                    }
                    
                    // Create a game object with the score information
                    let game = Game(
                        id: gameIdInt,
                        homeTeam: self.getNBAFullTeamName(homeTeamAbbr),
                        awayTeam: self.getNBAFullTeamName(awayTeamAbbr),
                        homeTeamAbbr: homeTeamAbbr,
                        awayTeamAbbr: awayTeamAbbr,
                        startTime: Date(),  // We don't know the exact start time here
                        status: gameStatus.lowercased(),
                        sportType: .nba,
                        homeScore: homeScore,
                        awayScore: awayScore,
                        currentInningOrQuarter: currentPeriod,
                        homeScoreByPeriod: homeScoresByPeriod,
                        awayScoreByPeriod: awayScoresByPeriod
                    )
                    
                    completion(game)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing NBA live score data: \(error)")
                completion(nil)
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    /// Update live scores for a list of games
    func updateLiveScores(games: [Game], completion: @escaping ([Game]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var updatedGames = games
        
        for (index, game) in games.enumerated() {
            // Only fetch updates for scheduled or live games
            if game.status == "scheduled" || game.status == "live" {
                // Create the game ID in the format expected by the API
                if let homeAbbr = game.homeTeamAbbr, let awayAbbr = game.awayTeamAbbr {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd"
                    let dateString = dateFormatter.string(from: game.startTime)
                    
                    let gameID = "\(dateString)_\(awayAbbr)@\(homeAbbr)"
                    
                    dispatchGroup.enter()
                    
                    // Convert Game.SportType to SportsService.SportType
                    let sportType = SportType.from(gameSportType: game.sportType)
                    
                    if sportType == .mlb {
                        fetchMLBLiveScore(gameID: gameID) { updatedGame in
                            if let updatedGame = updatedGame {
                                // Preserve the original start time
                                var game = updatedGame
                                game.startTime = games[index].startTime
                                DispatchQueue.main.async {
                                    updatedGames[index] = game
                                }
                            }
                            dispatchGroup.leave()
                        }
                    } else {
                        fetchNBALiveScore(gameID: gameID) { updatedGame in
                            if let updatedGame = updatedGame {
                                // Preserve the original start time
                                var game = updatedGame
                                game.startTime = games[index].startTime
                                DispatchQueue.main.async {
                                    updatedGames[index] = game
                                }
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(updatedGames)
        }
    }
    
    // MARK: - MLB API Methods
    
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
        guard let url = URL(string: mlbBaseURL + endpoint) else {
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
                    let games = self.convertMLBApiGamesToGames(apiResponse.body)
                    completion(games)
                    return
                } catch {
                    print("Could not decode as MLBApiResponse: \(error)")
                    
                    // Try to parse as a direct array of games
                    do {
                        let apiGames = try decoder.decode([MLBApiGame].self, from: data)
                        let games = self.convertMLBApiGamesToGames(apiGames)
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
                                let games = self.convertMLBApiGamesToGames(apiGames)
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
    
    // MARK: - NBA API Methods
    
    /// Fetch NBA schedule with retry mechanism
    private func fetchNBASchedule(date: Date, attempts: Int, completion: @escaping ([Game]?) -> Void) {
        guard attempts > 0 else {
            print("No more retry attempts left for NBA API")
            completion(nil)
            return
        }
        
        // Get the date in YYYYMMDD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        
        // API endpoint to get games for the date
        let endpoint = "/getNBAGamesForDate?gameDate=\(dateString)"
        
        print("Fetching NBA games for date: \(dateString)")
        
        // Construct the URL
        guard let url = URL(string: nbaBaseURL + endpoint) else {
            print("Error: invalid URL")
            completion(nil)
            return
        }
        
        // Create the request with headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue("tank01-fantasy-stats.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        
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
                    self.fetchNBASchedule(date: date, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            // Handle errors
            if let error = error {
                print("Error fetching NBA data: \(error)")
                
                // Wait and retry
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchNBASchedule(date: date, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                print("No data returned from NBA API")
                
                // Wait and retry
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchNBASchedule(date: date, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            do {
                // For debugging: print the response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("NBA API Response (first 200 chars): \(String(jsonString.prefix(200)))")
                }
                
                // Parse the JSON response
                let decoder = JSONDecoder()
                
                // Parse as the expected structure
                do {
                    let apiResponse = try decoder.decode(NBAApiResponse.self, from: data)
                    let games = self.convertNBAApiGamesToGames(apiResponse.body)
                    completion(games)
                    return
                } catch {
                    print("Could not decode as NBAApiResponse: \(error)")
                    
                    // Try another approach with direct deserialization
                    do {
                        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        if let bodyData = responseDict?["body"] as? [[String: Any]] {
                            let bodyJsonData = try JSONSerialization.data(withJSONObject: bodyData)
                            let apiGames = try decoder.decode([NBAApiGame].self, from: bodyJsonData)
                            let games = self.convertNBAApiGamesToGames(apiGames)
                            completion(games)
                            return
                        }
                    } catch {
                        print("All NBA parsing attempts failed: \(error)")
                        completion(nil)
                    }
                }
            } catch {
                print("Error handling NBA data: \(error)")
                
                // Wait and retry
                let delay = pow(2.0, Double(3 - attempts)) // 1, 2, 4 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.fetchNBASchedule(date: date, attempts: attempts - 1, completion: completion)
                }
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    // MARK: - Data Conversion Methods
    
    /// Convert MLB API games to app Game model
    private func convertMLBApiGamesToGames(_ apiGames: [MLBApiGame]) -> [Game] {
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
            
            let game = Game(
                id: gameId,
                homeTeam: getMLBFullTeamName(apiGame.home),
                awayTeam: getMLBFullTeamName(apiGame.away),
                homeTeamAbbr: apiGame.home,
                awayTeamAbbr: apiGame.away,
                startTime: startTime,
                status: "scheduled",  // Default status
                sportType: .mlb
            )
            
            games.append(game)
        }
        
        return games
    }
    
    /// Convert NBA API games to app Game model
    private func convertNBAApiGamesToGames(_ apiGames: [NBAApiGame]) -> [Game] {
        var games = [Game]()
        
        for apiGame in apiGames {
            // Set default game time to 7:30 PM since API doesn't provide times
            let calendar = Calendar.current
            var startTimeComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            startTimeComponents.hour = 19
            startTimeComponents.minute = 30
            let startTime = calendar.date(from: startTimeComponents) ?? Date()
            
            // Create a unique game ID
            let gameId: Int
            let components = apiGame.gameID.split(separator: "_")
            if components.count >= 2 {
                let dateComponent = components[0]
                let teamsComponent = components[1]
                
                // Create a hash from the teams string
                let teamsHash = abs(teamsComponent.hashValue % 10000)
                
                // Combine with a unique ID using last 4 digits of date + teams hash
                if let dateInt = Int(dateComponent.suffix(4)) {
                    gameId = (dateInt * 10000) + teamsHash + 5000000 // Add offset to avoid MLB ID collisions
                } else {
                    gameId = teamsHash + 5000000 + Int.random(in: 1000...9999)
                }
            } else {
                gameId = abs(apiGame.gameID.hashValue % 1000000) + 5000000
            }
            
            let game = Game(
                id: gameId,
                homeTeam: getNBAFullTeamName(apiGame.home),
                awayTeam: getNBAFullTeamName(apiGame.away),
                homeTeamAbbr: apiGame.home,
                awayTeamAbbr: apiGame.away,
                startTime: startTime,
                status: "scheduled",  // Default status
                sportType: .nba
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
    
    /// Get full MLB team name from abbreviation
    private func getMLBFullTeamName(_ abbreviation: String) -> String {
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
    
    /// Get full NBA team name from abbreviation
    private func getNBAFullTeamName(_ abbreviation: String) -> String {
        let teamNames: [String: String] = [
            "ATL": "Atlanta Hawks",
            "BOS": "Boston Celtics",
            "BKN": "Brooklyn Nets",
            "CHA": "Charlotte Hornets",
            "CHI": "Chicago Bulls",
            "CLE": "Cleveland Cavaliers",
            "DAL": "Dallas Mavericks",
            "DEN": "Denver Nuggets",
            "DET": "Detroit Pistons",
            "GSW": "Golden State Warriors",
            "HOU": "Houston Rockets",
            "IND": "Indiana Pacers",
            "LAC": "LA Clippers",
            "LAL": "Los Angeles Lakers",
            "MEM": "Memphis Grizzlies",
            "MIA": "Miami Heat",
            "MIL": "Milwaukee Bucks",
            "MIN": "Minnesota Timberwolves",
            "NOP": "New Orleans Pelicans",
            "NYK": "New York Knicks",
            "OKC": "Oklahoma City Thunder",
            "ORL": "Orlando Magic",
            "PHI": "Philadelphia 76ers",
            "PHO": "Phoenix Suns",
            "POR": "Portland Trail Blazers",
            "SAC": "Sacramento Kings",
            "SAS": "San Antonio Spurs",
            "TOR": "Toronto Raptors",
            "UTA": "Utah Jazz",
            "WAS": "Washington Wizards"
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
                status: "scheduled",
                sportType: .mlb
            ),
            Game(
                id: 2,
                homeTeam: "St. Louis Cardinals",
                awayTeam: "Chicago Cubs",
                homeTeamAbbr: "STL",
                awayTeamAbbr: "CHC",
                startTime: Calendar.current.date(bySettingHour: 20, minute: 15, second: 0, of: Date()) ?? Date(),
                status: "scheduled",
                sportType: .mlb
            ),
            Game(
                id: 3,
                homeTeam: "Los Angeles Dodgers",
                awayTeam: "San Francisco Giants",
                homeTeamAbbr: "LAD",
                awayTeamAbbr: "SF",
                startTime: Calendar.current.date(bySettingHour: 22, minute: 10, second: 0, of: Date()) ?? Date(),
                status: "scheduled",
                sportType: .mlb
            )
        ]
    }
    
    /// Get mock NBA games for testing
    func getMockNBAGames() -> [Game] {
        return [
            Game(
                id: 5000001,
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                homeTeamAbbr: "LAL",
                awayTeamAbbr: "BOS",
                startTime: Calendar.current.date(bySettingHour: 19, minute: 30, second: 0, of: Date()) ?? Date(),
                status: "scheduled",
                sportType: .nba
            ),
            Game(
                id: 5000002,
                homeTeam: "Golden State Warriors",
                awayTeam: "Brooklyn Nets",
                homeTeamAbbr: "GSW",
                awayTeamAbbr: "BKN",
                startTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                status: "scheduled",
                sportType: .nba
            ),
            Game(
                id: 5000003,
                homeTeam: "Miami Heat",
                awayTeam: "Chicago Bulls",
                homeTeamAbbr: "MIA",
                awayTeamAbbr: "CHI",
                startTime: Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date()) ?? Date(),
                status: "scheduled",
                sportType: .nba
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

struct NBAApiResponse: Codable {
    let statusCode: Int
    let body: [NBAApiGame]
}

struct NBAApiGame: Codable {
    let gameID: String
    let teamIDAway: String
    let away: String
    let gameDate: String
    let teamIDHome: String
    let home: String
}

// MARK: - API Response Models for Live Scores

struct MLBLiveScoreResponse: Codable {
    let statusCode: Int
    let body: MLBLiveScoreBody
}

struct MLBLiveScoreBody: Codable {
    let decisions: [MLBDecision]?
    let gameStatus: String
    let lastUpdated: Int?
    let currentBatter: String?
    let gameDate: String
    let awayResult: String?
    let currentCount: String?
    let homeResult: String?
    let away: String
    let lineScore: MLBLineScore
    let onDeck: String?
    let currentOuts: String?
    let currentPitcher: String?
    let currentInning: String
    let gameID: String
    let home: String
    let gameStatusCode: String?
}

struct MLBDecision: Codable {
    let decision: String
    let playerID: String
    let team: String
}

struct MLBLineScore: Codable {
    let away: MLBTeamScore
    let home: MLBTeamScore
}

struct MLBTeamScore: Codable {
    let H: String
    let R: String
    let team: String
    let scoresByInning: [String: String]
    let E: String
}

struct NBABoxScoreResponse: Codable {
    let statusCode: Int
    let body: NBABoxScoreBody
}

struct NBABoxScoreBody: Codable {
    let gameStatus: String
    let arenaCapacity: String?
    let referees: String?
    let arena: String?
    let teamStats: [String: NBATeamStats]?
    let gameDate: String
    let homePts: String
    let teamIDHome: String?
    let awayResult: String?
    let homeResult: String?
    let teamIDAway: String?
    let away: String
    let attendance: String?
    let lineScore: NBALineScore
    let gameLocation: String?
    let gameClock: String
    let awayPts: String
    let gameID: String
    let home: String
}

struct NBATeamStats: Codable {
    let pts: String?
    let ast: String?
    let reb: String?
    let blk: String?
    let stl: String?
    let TOV: String?
    // Add other stats as needed
}

struct NBALineScore: Codable {
    let CLE: NBAQuarterScore?
    let SA: NBAQuarterScore?
    // Dynamic keys for teams
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        // Attempt to decode home team
        if let homeKey = DynamicCodingKeys(stringValue: "CLE") {
            self.CLE = try container.decodeIfPresent(NBAQuarterScore.self, forKey: homeKey)
        } else {
            self.CLE = nil
        }
        
        // Attempt to decode away team
        if let awayKey = DynamicCodingKeys(stringValue: "SA") {
            self.SA = try container.decodeIfPresent(NBAQuarterScore.self, forKey: awayKey)
        } else {
            self.SA = nil
        }
    }
}

struct NBAQuarterScore: Codable {
    let Q1: String?
    let Q2: String?
    let Q3: String?
    let Q4: String?
    let totalPts: String?
} 