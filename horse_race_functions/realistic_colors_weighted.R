#------------------------------------------------------------
# realistic_colors_weighted
#------------------------------------------------------------
# Purpose:
#   Create a weighted vector of realistic horse coat colors,
#   where common colors (bays and chestnuts) appear more often
#   than rare ones.  Useful for assigning believable random
#   colors to simulated horses.
#
# Description:
#   This vector repeats hex codes according to approximate
#   real-world frequency so that a simple random sample()
#   will naturally favor common coats.
#
# Color groups:
#   - Bays (very common)     → replicated 3×
#   - Chestnuts (common)     → replicated 2×
#   - Blacks (moderate)      → replicated 2×
#   - Grays (less common)    → replicated 1×
#   - Specials (rare)        → single copy each
#
# Usage:
#   color <- sample(realistic_colors_weighted, 1)
#   horses$coat <- sample(realistic_colors_weighted, nrow(horses), replace = TRUE)
#
# Returns:
#   A character vector of hex color codes.
#
# Example:
#   plot(1:length(realistic_colors_weighted),
#        col = realistic_colors_weighted,
#        pch = 19, cex = 2)
#------------------------------------------------------------
# Weighted random (matches real-world frequency)
realistic_colors_weighted <- c(
  rep(c("#8B4513", "#654321", "#A0522D", "#CD853F"), 3),  # Bays - common
  rep(c("#D2691E", "#B8860B", "#CD5C5C", "#E9967A"), 2),  # Chestnuts - common
  rep(c("#2F4F4F", "#1C1C1C"), 2),                        # Blacks - moderate
  rep(c("#C0C0C0", "#A9A9A9", "#D3D3D3"), 1),            # Grays - less common
  c("#FFD700", "#DAA520", "#C19A6B", "#F5DEB3"),
  # Special colors - rare
)

#ALLCOLORS-csv_to_js_grass(c(29, 1, 9, 4,
#34, 7,12, 16,
#3, 5,
#14,46,42,
#31, 10, 13, 2))

#set.seed(42)
#horses$color<- sample(realistic_colors_weighted, 
                               #nrow(horses), 
                               #replace = TRUE)