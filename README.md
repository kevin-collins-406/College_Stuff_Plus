# College Baseball Stuff+ and Pitcher Similarity Scores

## Overview
A comprehensive machine learning toolkit for evaluating college baseball pitchers using MLB-derived methodologies. Combines **Stuff+ prediction models** and **pitcher similarity analysis** to provide advanced scouting and player development insights. This system requires training on MLB Statcast data before application to college TrackMan datasets.

## Workflow Overview
This analysis requires a **5-step process**:
1. **Data Collection** - Scrape 3 years of MLB Statcast data
2. **Model Training** - Train Stuff+ models on MLB data using reference college dataset
3. **Analysis** - Apply trained models to new college data
4. **Similarity Analysis** - Calculate pitcher similarity scores
5. **Presentation** - Display results in interactive Shiny dashboard

## Step-by-Step Instructions

### Step 1: Data Collection
Run `baseballR_Scrape.Rmd` to collect MLB training data:
```r
# Modify date ranges in the script for each year:
# For 2023 data:
start_date <- as.Date("2023-03-30")
end_date   <- as.Date("2023-10-01")

# For 2024 data:
start_date <- as.Date("2024-03-28") 
end_date   <- as.Date("2024-09-29")

# For 2025 data:
start_date <- as.Date("2025-03-27")
end_date   <- as.Date("2025-09-28")
```

**Required Output Files:**
- `statcast_2023_pitch_data.csv`
- `statcast_2024_pitch_data.csv` 
- `statcast_2025_pitch_data.csv`

**Important:** File names must match exactly as the training script expects these specific filenames.

### Step 2: Model Training
Run `Stuff+_Step1.Rmd` with the required input files:

**Required Input Files:**
- `statcast_2023_pitch_data.csv` (from Step 1)
- `statcast_2024_pitch_data.csv` (from Step 1)
- `statcast_2025_pitch_data.csv` (from Step 1)
- `ACC_SEC_pitchers_spring2025.csv` (reference college dataset)

**Output:** This saves trained models and standardization parameters to your computer for use in analysis.

### Step 3: Analysis on New Data
Run `Stuff+_Step2.Rmd` to analyze your college data:
```r
# MODIFY THESE LINES for your dataset:
new_data <- read_csv("YOUR_DATASET.csv")  # Change filename; note that a sample file `2025_fall_scrimmage_data.csv` is included in the repository
analysis_date <- "YOUR_DATE"              # Change date for labeling
```

**Data Requirements:** Your CSV file must follow the same column structure as `2025_fall_scrimmage_data.csv`:
- `Pitcher`, `RelSpeed`, `SpinRate`, `HorzBreak`, `InducedVertBreak`
- `Extension`, `RelHeight`, `RelSide`, `TaggedPitchType`
- `PitcherThrows`, `GameID`, `PitchCall`

**Output:** Generates Stuff+ scores, CSW%, velocity metrics.

### Step 4: Pitcher Similarity Analysis
Run `Pitcher_Similarity_Scores.Rmd` to calculate pitcher similarity:
```r
# MODIFY THIS LINE for your dataset:
new_data <- read.csv("YOUR_DATASET.csv")  # Must match Step 3 filename
```

**Functionality:**
- **Similarity Matrix Creation**: Calculates pairwise similarity scores for all pitchers
- **Interactive Queries**: Find pitchers most similar to any player in your dataset
- **Validation Tools**: Includes PCA visualization, heatmaps, and feature importance analysis

**Key Functions Generated:**
```r
# Find similar pitchers
find_pitcher_similarities("Pitcher Name", top_n = 5)

# View detailed pitcher profiles
show_pitcher_details("Pitcher Name")

# See all available pitchers
print(rownames(similarity_matrix))
```

**Output:** 
- Similarity scores (0-100 scale) between all pitcher pairs
- Detailed arsenal comparisons
- Visual clustering and validation plots
- Feature importance analysis showing what drives similarity

### Step 5: Interactive Dashboard
Run `Stuff+_Shiny.R` for interactive results presentation:
```r
# IMPORTANT: These must match Step 3 inputs exactly:
filename <- "YOUR_DATASET.csv"    # Same as Step 3
date_label <- "YOUR_DATE"         # Same as Step 3
```

## System Requirements
```r
# Required packages:
install.packages(c(
  "tidyverse", "xgboost", "baseballr", "lubridate",
  "shiny", "DT", "plotly", "corrplot", "pheatmap"
))
```

## Model Outputs

### Stuff+ Analysis
- **Stuff+ Scores**: Normalized to 100 (league average), higher = better pitch quality
- **CSW%**: Called Strike + Whiff percentage by pitch type  
- **Average Velocity**: Primary metrics for each pitch in arsenal
- **Leaderboards**: Top performers per pitch type with comprehensive breakdowns

### Similarity Analysis
- **Similarity Scores**: 0-100 scale showing pitcher comparisons based on complete arsenals
- **Detailed Comparisons**: Side-by-side pitch characteristic analysis
- **Visual Clustering**: PCA plots showing pitcher style groupings
- **Similarity Heatmaps**: Matrix visualization of all pitcher relationships
- **Feature Importance**: Analysis of which characteristics drive similarity most
- **Interactive Functions**: Query system for finding comparable players

## Methodology

### Stuff+ Model
**Controlled Run Expectancy (CRE)**: Isolates pitch quality from game context by comparing actual vs. expected run value changes for specific event-state combinations.

**Cross-Level Application**: Models trained on MLB data are applied to college data using proper standardization techniques to enable fair comparison across competitive levels.

### Similarity Analysis
**Multi-Dimensional Distance**: Uses Euclidean distance on standardized pitcher profiles including:
- Average velocity, spin rate, and movement by pitch type
- Pitch usage rates and arsenal composition  
- Release point characteristics and consistency metrics

**Validation Methods**: Cross-validation with performance metrics, PCA visualization, and feature importance analysis to ensure meaningful similarity scores.

## File Structure
```
├── BaseballR_Scrape.Rmd              # Data collection
├── Stuff+_Step1.Rmd                  # Model training  
├── Stuff+_Step2.Rmd                  # Stuff+ analysis application
├── Pitcher_Similarity_Scores.Rmd     # Similarity analysis
├── Stuff+_Shiny.R                    # Interactive dashboard
├── ACC_SEC_pitchers_spring2025.csv   # Reference college dataset
├── 2025_fall_scrimmage_data.csv      # Example analysis dataset
└── README.md                         # This documentation
```

## Important Notes
- **File naming is critical** - Scripts expect exact filenames as specified
- **Date consistency** - Date labels in Step 3 and Step 5 must match exactly
- **Column structure** - New datasets must match the TrackMan format shown in example files
- **Processing time** - Full MLB data collection takes 20-30 minutes per season
- **Storage requirements** - Each season file is approximately 120MB
- **Similarity analysis** - Requires minimum 10 pitches per pitcher for reliable similarity scores

## Applications
- **Player Development**: Identify pitch quality improvement areas and find development role models
- **Recruiting**: Compare prospects using standardized metrics and find similar successful players
- **Game Planning**: Analyze opposing pitcher strengths/weaknesses and historical matchup data
- **Performance Tracking**: Monitor development over time with objective metrics
- **Scouting**: Find undervalued players with similar profiles to successful pitchers

## Author
**Kevin Collins**  
Graduate Student, Quantitative Economics, University of Pittsburgh  
Research Assistant, Pitt Baseball Analytics  

*Developed for the University of Pittsburgh Baseball program.*

---
*For questions about implementation or methodology, contact: [kacollinspitt@gmail.com]*
