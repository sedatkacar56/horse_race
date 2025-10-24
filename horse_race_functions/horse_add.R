#' Add Random Horses to Dataset or Save Existing Data
#'
#' This function either appends randomly generated horse data to an existing
#' dataset or saves the current global `horses` data frame to a CSV file.
#'
#' @param horse_number Integer. Number of new horses to generate and add.
#' @param overwrite Logical. If `TRUE`, the current `horses` object in the global
#'   environment is written to `"horses.csv"` and the function exits immediately.
#'   Default is `FALSE`.
#'
#' @details
#' When `overwrite = FALSE`, the function reads `"horse.csv"` (expected to exist
#' in the working directory) and adds randomly generated horses. Each new horse
#' receives:
#' \itemize{
#'   \item A randomly generated name (using \code{generate_horse_names()}).
#'   \item A random color in hexadecimal format.
#'   \item Randomized numeric stats within defined realistic ranges:
#'     \itemize{
#'       \item \code{baseSpeed:} 2.7–3.6
#'       \item \code{stamina:} 0.6–1.1
#'       \item \code{sprint:} 0.7–3.0
#'       \item \code{variance:} 0.2–1.0
#'       \item \code{fatigue:} 0.03–0.7
#'       \item \code{kick:} 0.01–0.9
#'       \item \code{finalBoost:} 0.8–2.0
#'     }
#'   \item An empty `Races` column filled with `NA`.
#' }
#'
#' The resulting dataset is returned and also printed with a message showing
#' how many new horses were added.
#'
#' @return A data frame containing the updated list of horses.
#'
#' @examples
#' \dontrun{
#' # Add 5 random horses to the dataset
#' horses <- horse_add(5)
#'
#' # Save current horses dataset to CSV and exit
#' horse_add(overwrite = TRUE)
#' }
#'
#' @export
horse_add <- function(horse_number, overwrite = F) {
  
  if(overwrite){
    write.csv(horses, "horse.csv")
    return(invisible(horses))
  }
  
  horses <- read.csv("horse.csv", row.names = 1)
  # Number of new horses to add
  n_new <- horse_number
  
  # Generate random horse names
  new_names <- generate_horse_names(n_new)
  
  # Generate random hex colors
  rand_color <- function(n) {
    paste0("#", toupper(sprintf("%06x", sample(0:0xFFFFFF, n, replace = TRUE))))
  }
  
  # Create new random horse rows
  new_df <- data.frame(
    name       = new_names,
    color      = rand_color(n_new),
    baseSpeed  = round(runif(n_new, 2.7, 3.6), 2),
    stamina    = round(runif(n_new, 0.6, 1.1), 2),
    sprint     = round(runif(n_new, 0.7, 3.0), 2),
    variance   = round(runif(n_new, 0.2, 1.0), 2),
    fatigue    = round(runif(n_new, 0.03, 0.7), 2),
    kick       = round(runif(n_new, 0.01, 0.9), 3),
    finalBoost = round(runif(n_new, 0.8, 2.0), 2),
    Races      = NA_real_
  )
  
  # Combine with the existing dataset
  horses <- rbind(horses, new_df)
  
  message("✅ Added ", n_new, " new horse(s). New total: ", nrow(horses))
  return(horses)
}