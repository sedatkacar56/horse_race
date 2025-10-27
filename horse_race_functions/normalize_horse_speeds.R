#------------------------------------------------------------
# normalize_horse_speeds()
#------------------------------------------------------------
# Purpose:
#   Normalize and rebalance horse performance metrics to create
#   more competitive racing behavior, preventing one horse from
#   dominating due to extreme raw stats.
#
# Description:
#   This function takes a data frame of horses with attributes
#   such as baseSpeed, stamina, sprint, fatigue, kick, and
#   finalBoost, and computes a composite performance score.
#   It ranks horses from best to worst, normalizes their base
#   speeds within a tight competitive range, and clips all other
#   performance metrics to realistic bounds.
#
# Steps:
#   1. Calculate performance_score using weighted contribution:
#      - baseSpeed: 40%
#      - stamina: 20%
#      - sprint: 15%
#      - inverse fatigue: 20%
#      - kick: 10%
#      - finalBoost: 5%
#
#   2. Rank horses from 1 (best) to N (worst).
#
#   3. Normalize baseSpeed so the fastest horse = 1.5 and
#      the slowest = 1.0, evenly spaced between.
#
#   4. Clamp other attributes to moderate ranges to prevent
#      extreme values that make races unbalanced.
#
# Arguments:
#   df : data.frame
#       A data frame containing columns:
#         baseSpeed, stamina, sprint, fatigue,
#         kick, finalBoost, variance (optional).
#
# Returns:
#   A modified data.frame with normalized performance attributes.
#
# Example:
#   horses <- data.frame(
#     baseSpeed = runif(10, 2.5, 3.5),
#     stamina = runif(10, 0.6, 1.2),
#     sprint = runif(10, 0.8, 1.6),
#     fatigue = runif(10, 0.1, 0.7),
#     kick = runif(10, 0.0, 0.4),
#     finalBoost = runif(10, 1.0, 2.0)
#   )
#   normalized_horses <- normalize_horse_speeds(horses)
#   head(normalized_horses)
#------------------------------------------------------------

# Normalize horse speeds for competitive racing
normalize_horse_speeds <- function(df) {
  
  # 1. Rank horses by their combined performance score
  df$performance_score <- (
    df$baseSpeed * 0.4 +      # 40% base speed importance
      df$stamina * 2 +           # 20% stamina
      df$sprint * 1.5 +          # 15% sprint
      (1 - df$fatigue) * 2 +     # 20% inverse fatigue
      df$kick * 1 +              # 10% kick
      df$finalBoost * 0.5        # 5% final boost
  )
  
  # 2. Rank from 1 (best) to N (worst)
  df$rank <- rank(-df$performance_score, ties.method = "first")
  
  # 3. Normalize baseSpeed to range: 2.8 to 3.4 (tight range!)
  # Top horse = 3.4, Bottom horse = 2.8, evenly distributed
  min_speed <- 1
  max_speed <- 1.5
  n <- nrow(df)
  
  df$baseSpeed <- min_speed + (max_speed - min_speed) * (1 - (df$rank - 1) / (n - 1))
  
  # 4. Keep other stats but moderate them
  df$sprint <- pmin(pmax(df$sprint, 1.0), 1.5)      # Range: 1.0 to 1.8
  df$stamina <- pmin(pmax(df$stamina, 0.7), 1.0)    # Range: 0.7 to 1.0
  df$variance <- pmin(pmax(df$variance, 0.8), 1.5)  # Range: 0.2 to 0.6
  df$fatigue <- pmin(pmax(df$fatigue, 0.2), 0.5)    # Range: 0.2 to 0.5
  df$kick <- pmin(pmax(df$kick, 0.0), 0.3)          # Range: 0.3 to 0.7
  df$finalBoost <- pmin(pmax(df$finalBoost, 1.0), 2) # Range: 1.1 to 1.5
  
  # Round to 2 decimals
  df$baseSpeed <- round(df$baseSpeed, 2)
  df$sprint <- round(df$sprint, 2)
  df$stamina <- round(df$stamina, 2)
  df$variance <- round(df$variance, 2)
  df$fatigue <- round(df$fatigue, 2)
  df$kick <- round(df$kick, 2)
  df$finalBoost <- round(df$finalBoost, 2)
  
  df$performance_score <- NULL
  df$performance_score <- NULL
  df$rank <- NULL
  return(df)
}



#Rank 1 (best):  speed 3.40 ⭐⭐⭐⭐⭐
#Rank 2:         speed 3.35 ⭐⭐⭐⭐
#Rank 3:         speed 3.30 ⭐⭐⭐
#Rank 4:         speed 3.25 ⭐⭐
#Rank 5 (worst): speed 3.20 ⭐