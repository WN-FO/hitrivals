import Foundation
import UIKit
import SwiftUI

/// Manages team logo loading and caching
class TeamLogoManager {
    static let shared = TeamLogoManager()
    
    // Logo cache to avoid reloading
    private var logoCache: [String: UIImage] = [:]
    
    // Mapping from MLB team abbreviations to asset names (now just use the abbreviation directly)
    private let mlbTeamAbbreviations = [
        "ARI", "ATL", "BAL", "BOS", "CHC", "CWS", "CIN", "CLE", "COL", "DET",
        "HOU", "KC", "LAA", "LAD", "MIA", "MIL", "MIN", "NYM", "NYY", "OAK",
        "PHI", "PIT", "SD", "SF", "SEA", "STL", "TB", "TEX", "TOR", "WSH"
    ]
    
    // Mapping from NBA team abbreviations to asset names (now just use the abbreviation directly)
    private let nbaTeamAbbreviations = [
        "ATL", "BOS", "BKN", "CHA", "CHI", "CLE", "DAL", "DEN", "DET", "GSW",
        "HOU", "IND", "LAC", "LAL", "MEM", "MIA", "MIL", "MIN", "NOP", "NYK",
        "OKC", "ORL", "PHI", "PHO", "POR", "SAC", "SAS", "TOR", "UTA", "WAS"
    ]
    
    private init() {
        // Initialize and verify logo files are accessible
        print("TeamLogoManager initialized, verified MLB teams: \(verifyMLBLogos().count), NBA teams: \(verifyNBALogos().count)")
    }
    
    /// Get logo for a team by its abbreviation and sport type
    func logoForTeam(abbreviation: String, sportType: SportsService.SportType) -> UIImage? {
        // Check cache first
        let sportTypeString = sportType == .nba ? "NBA" : "MLB"
        let cacheKey = "\(sportTypeString)_\(abbreviation)"
        if let cachedLogo = logoCache[cacheKey] {
            return cachedLogo
        }
        
        let logoImage = loadLogoImage(for: abbreviation, sportType: sportType)
        
        // Store in cache if found
        if let logoImage = logoImage {
            logoCache[cacheKey] = logoImage
        }
        
        return logoImage
    }
    
    /// Load the logo image for a team from the asset catalog
    private func loadLogoImage(for abbreviation: String, sportType: SportsService.SportType) -> UIImage? {
        // If empty abbreviation, return nil
        if abbreviation.isEmpty {
            return nil
        }
        
        // Create the asset name based on league and abbreviation
        let assetName = "TeamLogos/\(sportType == .nba ? "NBA" : "MLB")/\(abbreviation)"
        
        // Load the image from assets
        return UIImage(named: assetName)
    }
    
    /// Verify MLB logos are accessible
    func verifyMLBLogos() -> [String] {
        return verifyLogos(abbreviations: mlbTeamAbbreviations, sportType: .mlb)
    }
    
    /// Verify NBA logos are accessible
    func verifyNBALogos() -> [String] {
        return verifyLogos(abbreviations: nbaTeamAbbreviations, sportType: .nba)
    }
    
    /// Verify logos are accessible by trying to load each one
    private func verifyLogos(abbreviations: [String], sportType: SportsService.SportType) -> [String] {
        var foundTeams: [String] = []
        
        for abbr in abbreviations {
            if loadLogoImage(for: abbr, sportType: sportType) != nil {
                foundTeams.append(abbr)
            }
        }
        
        return foundTeams
    }
    
    /// Provide a SwiftUI Image for a team
    func logoImage(for abbreviation: String, sportType: SportsService.SportType) -> Image? {
        // For asset-based images, we can directly use the asset name
        let assetName = "TeamLogos/\(sportType == .nba ? "NBA" : "MLB")/\(abbreviation)"
        
        // First try direct asset access which is more efficient
        if UIImage(named: assetName) != nil {
            return Image(assetName)
        }
        
        return nil
    }
} 