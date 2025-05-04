#!/usr/bin/swift

import Foundation

// Mapping from MLB team abbreviations to file names
let mlbTeamMap: [String: String] = [
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
    "KC": "Kansas City Royal", // Note: Filename has typo
    "LAA": "Los Angeles Angeles", // Note: Filename has typo
    "LAD": "Los Angeles Dodgers",
    "MIA": "Miami Marlins",
    "MIL": "Milwaukee Brewers",
    "MIN": "Minnesota Twins",
    "NYM": "New York Mets",
    "NYY": "New York Yankees",
    "OAK": "Athletics",
    "PHI": "Philadelphia Phillies",
    "PIT": "Pittsburgh Pirates",
    "SD": "San Diego Padres",
    "SF": "San Francisco Giants",
    "SEA": "Seattle Mariners",
    "STL": "St. Louis Cardina", // Note: Filename has typo
    "TB": "Tampa Bay Rays",
    "TEX": "Texas Rangers",
    "TOR": "Toronto Blue Jays",
    "WSH": "Washington Nationals"
]

// Mapping from NBA team abbreviations to file names
let nbaTeamMap: [String: String] = [
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
    "IND": "indiana Pacers", // Note: Filename has lowercase 'i'
    "LAC": "Los Angeles Clippers", 
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

// Function to rename files
func renameLogoFiles(in directory: String, using mapping: [String: String], createCopy: Bool = true) {
    let fileManager = FileManager.default
    let basePath = NSHomeDirectory() + "/Desktop/" + directory
    
    // Ensure directory exists
    var isDir: ObjCBool = false
    guard fileManager.fileExists(atPath: basePath, isDirectory: &isDir), isDir.boolValue else {
        print("Directory does not exist or is not a directory: \(basePath)")
        return
    }
    
    print("\nRenaming files in \(directory):")
    print("================================")
    
    // Create a new directory for renamed files if using copy mode
    let targetDir = createCopy ? basePath + "_abbr" : basePath
    
    if createCopy {
        do {
            try fileManager.createDirectory(atPath: targetDir, withIntermediateDirectories: true, attributes: nil)
            print("Created directory for renamed files: \(targetDir)")
        } catch {
            print("Error creating directory: \(error)")
            return
        }
    }
    
    // Process each mapping and copy/rename the file
    for (abbr, originalName) in mapping {
        let sourcePath = basePath + "/" + originalName + ".png"
        let destinationPath = targetDir + "/" + abbr + ".png"
        
        // Check if original file exists
        if fileManager.fileExists(atPath: sourcePath) {
            do {
                if createCopy {
                    // Make a copy with the new name
                    try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
                    print("✅ Copied: \(originalName).png -> \(abbr).png")
                } else {
                    // Rename the file
                    try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
                    print("✅ Renamed: \(originalName).png -> \(abbr).png")
                }
            } catch {
                print("❌ Error processing \(abbr): \(error)")
            }
        } else {
            print("❓ Original file not found: \(sourcePath)")
        }
    }
}

// Run the rename operations
print("Starting logo file renaming process...")
renameLogoFiles(in: "mlblogo", using: mlbTeamMap)
renameLogoFiles(in: "nbalogo", using: nbaTeamMap)
print("\nRenaming complete! New directories created with abbreviation-based filenames.")
print("To use the renamed files in the app, update the base paths in TeamLogoManager.swift") 