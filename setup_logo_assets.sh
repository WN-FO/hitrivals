#!/bin/bash

# MLB Teams
MLB_TEAMS=(
  "ARI:Arizona Diamondbacks"
  "ATL:Atlanta Braves"
  "BAL:Baltimore Orioles"
  "BOS:Boston Red Sox"
  "CHC:Chicago Cubs"
  "CWS:Chicago White Sox"
  "CIN:Cincinnati Reds"
  "CLE:Cleveland Guardians"
  "COL:Colorado Rockies"
  "DET:Detroit Tigers"
  "HOU:Houston Astros"
  "KC:Kansas City Royal"
  "LAA:Los Angeles Angeles"
  "LAD:Los Angeles Dodgers"
  "MIA:Miami Marlins"
  "MIL:Milwaukee Brewers"
  "MIN:Minnesota Twins"
  "NYM:New York Mets"
  "NYY:New York Yankees"
  "OAK:Athletics"
  "PHI:Philadelphia Phillies"
  "PIT:Pittsburgh Pirates"
  "SD:San Diego Padres"
  "SF:San Francisco Giants"
  "SEA:Seattle Mariners"
  "STL:St. Louis Cardina"
  "TB:Tampa Bay Rays"
  "TEX:Texas Rangers"
  "TOR:Toronto Blue Jays"
  "WSH:Washington Nationals"
)

# NBA Teams
NBA_TEAMS=(
  "ATL:Atlanta Hawks"
  "BOS:Boston Celtics"
  "BKN:Brooklyn Nets"
  "CHA:Charlotte Hornets"
  "CHI:Chicago Bulls"
  "CLE:Cleveland Cavaliers"
  "DAL:Dallas Mavericks"
  "DEN:Denver Nuggets"
  "DET:Detroit Pistons"
  "GSW:Golden State Warriors"
  "HOU:Houston Rockets"
  "IND:indiana Pacers"
  "LAC:Los Angeles Clippers"
  "LAL:Los Angeles Lakers"
  "MEM:Memphis Grizzlies"
  "MIA:Miami Heat"
  "MIL:Milwaukee Bucks"
  "MIN:Minnesota Timberwolves"
  "NOP:New Orleans Pelicans"
  "NYK:New York Knicks"
  "OKC:Oklahoma City Thunder"
  "ORL:Orlando Magic"
  "PHI:Philadelphia 76ers"
  "PHO:Phoenix Suns"
  "POR:Portland Trail Blazers"
  "SAC:Sacramento Kings"
  "SAS:San Antonio Spurs"
  "TOR:Toronto Raptors"
  "UTA:Utah Jazz"
  "WAS:Washington Wizards"
)

# Function to create asset structure for a team
create_asset() {
  local league=$1
  local abbr=$2
  local name=$3
  local asset_dir="HitRivals/Assets.xcassets/TeamLogos/${league}/${abbr}.imageset"
  
  # Create directory
  mkdir -p "$asset_dir"
  
  # Create Contents.json
  cat > "$asset_dir/Contents.json" << EOF
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${abbr}.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

  # Copy the image file
  local source_path="${HOME}/Desktop/${league}logo/${name}.png"
  if [ -f "$source_path" ]; then
    cp "$source_path" "$asset_dir/${abbr}.png"
    echo "✅ Added ${league} team: ${abbr} (${name})"
  else
    echo "❌ Source image not found: ${source_path}"
  fi
}

# Process MLB teams
echo "Processing MLB team logos..."
for team in "${MLB_TEAMS[@]}"; do
  IFS=":" read -r abbr name <<< "$team"
  create_asset "MLB" "$abbr" "$name"
done

# Process NBA teams
echo "Processing NBA team logos..."
for team in "${NBA_TEAMS[@]}"; do
  IFS=":" read -r abbr name <<< "$team"
  create_asset "NBA" "$abbr" "$name"
done

echo "Logo asset setup complete!" 