#' Convert a horse attribute CSV to a JavaScript file for web use
#'
#' This function reads a CSV file containing horse racing attributes
#' (e.g., name, color, speed, stamina, etc.), converts the data into
#' JavaScript array syntax, and saves it as a `horses.js` file that defines
#' a global variable `window.HORSE_DATA`.
#'
#' @param csv_path Character string. Path to the input CSV file.
#'   Default is `"horses.csv"` in the current working directory.
#' @param out_filename Character string. Name of the output JavaScript file.
#'   Default is `"horses.js"`. The file will be saved in the same folder
#'   as the CSV.
#'
#' @details
#' The function automatically:
#' \itemize{
#'   \item Detects whether the file is comma- or tab-delimited.
#'   \item Removes the first column if it contains row numbers or is named `#`.
#'   \item Normalizes header names (e.g., converts `basespeed` → `baseSpeed`).
#'   \item Converts numeric columns to numeric types.
#'   \item Writes a JavaScript file containing a global variable:
#'     \code{window.HORSE_DATA = [...];}
#' }
#'
#' The input CSV should have these headers (case-insensitive):
#' \code{name, color, baseSpeed, stamina, sprint, variance, fatigue, kick, finalBoost}.
#'
#' @return Invisibly returns the output file path.
#'
#' @examples
#' \dontrun{
#' csv_to_js("C:/Users/skacar/Documents/horse_race/horses.csv")
#' }
#'
#' @export
#' 
csv_to_js <- function(selected_horses, csv_path = "horses.csv", out_filename = "horses.js") {
  
  `%||%` <- function(a, b) if (!is.null(a)) a else b
  
  # Detect delimiter (comma or tab)
  first_line <- readr::read_lines(csv_path, n_max = 1)
  delim <- if (grepl("\t", first_line)) "\t" else ","
  df <- readr::read_delim(csv_path, delim = delim, show_col_types = FALSE, trim_ws = TRUE)
  
  # ---- Keep only columns 2–9 (drop index & extras) ----
  if (ncol(df) >= 9) {
    df <- df[, 2:10, drop = FALSE]
    df <- df[selected_horses, ]

  } else {
    stop("CSV file does not have enough columns (need at least 9).")
  }
  
  # ---- Normalize column names ----
  nm <- tolower(names(df))
  map <- c(
    name        = "name",
    color       = "color",
    basespeed   = "baseSpeed",
    stamina     = "stamina",
    sprint      = "sprint",
    variance    = "variance",
    fatigue     = "fatigue",
    kick        = "kick",
    finalboost  = "finalBoost"
  )
  names(df) <- vapply(nm, function(x) map[[x]] %||% x, character(1))
  
  # ---- Convert numeric columns ----
  num_cols <- setdiff(names(df), c("name","color"))
  for (cc in num_cols) df[[cc]] <- suppressWarnings(as.numeric(df[[cc]]))
  
  # ---- Convert to JS and save ----
  js_array <- jsonlite::toJSON(df, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
  js_text  <- paste0("window.HORSE_DATA = ", js_array, ";\n")
  
  out_path <- file.path(dirname(csv_path), out_filename)
  writeLines(js_text, out_path)
  
  message("✅ JS file saved to: ", out_path)
  invisible(out_path)
}

