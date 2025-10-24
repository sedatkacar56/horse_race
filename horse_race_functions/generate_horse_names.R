#' Generate Random Horse Names
#'
#' Creates a vector of randomly generated horse-style names, combining
#' evocative adjectives and nouns (e.g., *"Majestic Storm"*, *"Golden Rider"*)
#' with an optional small chance of fantasy-style one-word names
#' (e.g., *"Shadowfax"*, *"Embermane"*).
#'
#' @param n Integer. Number of names to generate. Default is 20.
#'
#' @details
#' The function draws random pairs of adjectives and nouns to form
#' horse-style names that resemble real racehorse naming patterns.
#' About 10% of the generated names are replaced with single-word
#' fantasy names for variety.
#'
#' The generated names are not guaranteed to be unique, but for most
#' practical uses (up to a few hundred horses), collisions are rare.
#' 
#' You can ensure uniqueness with:
#' \code{unique(generate_horse_names(n))}
#'
#' @return A character vector of length \code{n}, containing horse names.
#'
#' @examples
#' # Generate 10 random horse names
#' set.seed(123)
#' generate_horse_names(10)
#'
#' # Example output:
#' # "Majestic Storm" "Wild Blaze" "Shadow Wind" "Crimson Fury"
#' # "Thunderhoof" "Iron Comet" "Swift Knight" "Brightstar"
#' # "Golden Rider" "Phantom Arrow"
#'
#' @export
generate_horse_names <- function(n = 20) {
  adjectives <- c("Silver","Golden","Shadow","Crimson","Wild","Swift","Iron",
                  "Majestic","Blazing","Silent","Midnight","Thunder","Rapid",
                  "Phantom","Brave","Fire","Stormy","Electric","Fierce","Radiant")
  
  nouns <- c("Blaze","Spirit","Comet","Rider","Wind","Arrow","Echo","Flame",
             "Storm","Runner","Whisper","Drift","Falcon","Tornado","Knight",
             "Strike","Fury","Flash","Trail","Rocket")
  
  # Combine words randomly
  names <- paste(sample(adjectives, n, TRUE), sample(nouns, n, TRUE))
  
  # Add a small chance of one-word fantasy names
  fantasy <- c("Shadowfax","Eclipse","Windracer","Thunderhoof","Nightglow",
               "Skyblazer","Ironmane","Brightstar","Frosthoof","Embermane")
  replace(names, sample(seq_len(n), n/10), sample(fantasy, n/10, TRUE))
}