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
csv_to_js <- function(
    selected_horses,
    csv_path = "horses.csv",
    out_filename = "horses.js",
    backgroundTop = "#B8860B",
    backgroundBottom = "#8B5A2B",
    border = "#8B4513"
) {
  `%||%` <- function(a, b) if (!is.null(a)) a else b
  
  # Detect delimiter
  first_line <- readr::read_lines(csv_path, n_max = 1)
  delim <- if (grepl("\t", first_line)) "\t" else ","
  df <- readr::read_delim(csv_path, delim = delim, show_col_types = FALSE, trim_ws = TRUE)
  
  # Keep columns 2–10 (drop index col 1)
  if (ncol(df) < 10) stop("CSV must have at least 10 columns (index + 9 data columns).")
  df <- df[, 2:10, drop = FALSE]
  
  # Filter rows if provided
  if (!missing(selected_horses) && length(selected_horses)) {
    df <- df[selected_horses, , drop = FALSE]
  }
  
  # Optional normalization (assumes you defined this)
  if (exists("normalize_horse_speeds")) df <- normalize_horse_speeds(df)
  
  # Normalize column names
  nm <- tolower(names(df))
  map <- c(
    name = "name",
    color = "color",
    basespeed = "baseSpeed",
    stamina = "stamina",
    sprint = "sprint",
    variance = "variance",
    fatigue = "fatigue",
    kick = "kick",
    finalboost = "finalBoost"
  )
  names(df) <- vapply(nm, function(x) map[[x]] %||% x, character(1))
  
  # Convert numeric columns
  num_cols <- setdiff(names(df), c("name","color"))
  for (cc in num_cols) df[[cc]] <- suppressWarnings(as.numeric(df[[cc]]))
  
  # JS: HORSE_DATA
  js_array  <- jsonlite::toJSON(df, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
  js_horses <- paste0("window.HORSE_DATA = ", js_array, ";\n")
  
  # JS: TRACK_STYLE (quote safely via toJSON)
  q <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE)
  js_track <- sprintf(
    "window.TRACK_STYLE = {backgroundTop:%s, backgroundBottom:%s, border:%s};",
    q(backgroundTop), q(backgroundBottom), q(border)
  )
  
  # Combine and write
  js_track_horse <- paste(js_track, js_horses, sep = "\n\n")
  out_path <- file.path(dirname(csv_path), out_filename)
  writeLines(js_track_horse, out_path)
  
  message("✅ JS file saved to: ", out_path)
  invisible(out_path)
}



#' Convert a horse attribute CSV to a JavaScript file for web use
#'

csv_to_js_grass_position <- function(
    selected_horses,
    csv_path = "horses.csv",
    out_filename = "horses.js",
    backgroundTop = "#7CB342",
    backgroundBottom = "#558B2F",
    border = "#8B4513"
) {
  `%||%` <- function(a, b) if (!is.null(a)) a else b
  
  # Detect delimiter
  first_line <- readr::read_lines(csv_path, n_max = 1)
  delim <- if (grepl("\t", first_line)) "\t" else ","
  df <- readr::read_delim(csv_path, delim = delim, show_col_types = FALSE, trim_ws = TRUE)
  
  # Keep columns 2–10 (drop index col 1)
  if (ncol(df) < 12) stop("CSV must have at least 10 columns (index + 9 data columns).")
  df <- df[, 2:12, drop = FALSE]
  
  # Filter rows if provided
  if (!missing(selected_horses) && length(selected_horses)) {
    df <- df[selected_horses, , drop = FALSE]
  }
  
  
  # Normalize column names
  nm <- tolower(names(df))
  map <- c(
    name = "name",
    color = "color",
    basespeed = "baseSpeed",
    stamina = "stamina",
    sprint = "sprint",
    variance = "variance",
    fatigue = "fatigue",
    kick = "kick",
    finalboost = "finalBoost",
    position = "position",
    handicap = "handicap"
  )
  names(df) <- vapply(nm, function(x) map[[x]] %||% x, character(1))
  
  # Convert numeric columns
  num_cols <- setdiff(names(df), c("name","color"))
  for (cc in num_cols) df[[cc]] <- suppressWarnings(as.numeric(df[[cc]]))
  
  # JS: HORSE_DATA
  js_array  <- jsonlite::toJSON(df, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
  js_horses <- paste0("window.HORSE_DATA = ", js_array, ";\n")
  
  # JS: TRACK_STYLE (quote safely via toJSON)
  q <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE)
  js_track <- sprintf(
    "window.TRACK_STYLE = {backgroundTop:%s, backgroundBottom:%s, border:%s};",
    q(backgroundTop), q(backgroundBottom), q(border)
  )
  
  # Combine and write
  js_track_horse <- paste(js_track, js_horses, sep = "\n\n")
  out_path <- file.path(dirname(csv_path), out_filename)
  writeLines(js_track_horse, out_path)
  
  message("✅ JS file saved to: ", out_path)
  invisible(out_path)
}

#' Convert a horse attribute CSV to a JavaScript file for web use
#'
#'
csv_to_js_dirt <- function(
    selected_horses,
    csv_path = "horses.csv",
    out_filename = "horses.js",
    backgroundTop = "#B8860B",
    backgroundBottom = "#8B5A2B",
    border = "#8B4513"
) {
  `%||%` <- function(a, b) if (!is.null(a)) a else b
  
  # Detect delimiter
  first_line <- readr::read_lines(csv_path, n_max = 1)
  delim <- if (grepl("\t", first_line)) "\t" else ","
  df <- readr::read_delim(csv_path, delim = delim, show_col_types = FALSE, trim_ws = TRUE)
  
  # Keep columns 2–10 (drop index col 1)
  if (ncol(df) < 12) stop("CSV must have at least 10 columns (index + 9 data columns).")
  df <- df[, 2:12, drop = FALSE]
  
  # Filter rows if provided
  if (!missing(selected_horses) && length(selected_horses)) {
    df <- df[selected_horses, , drop = FALSE]
  }
  
  # Optional normalization (assumes you defined this)
  df <- normalize_horse_speeds(df)
  
  # Normalize column names
  nm <- tolower(names(df))
  map <- c(
    name = "name",
    color = "color",
    basespeed = "baseSpeed",
    stamina = "stamina",
    sprint = "sprint",
    variance = "variance",
    fatigue = "fatigue",
    kick = "kick",
    finalboost = "finalBoost",
    position = "position",
    handicap = "handicap"
  )
  names(df) <- vapply(nm, function(x) map[[x]] %||% x, character(1))
  
  # Convert numeric columns
  num_cols <- setdiff(names(df), c("name","color"))
  for (cc in num_cols) df[[cc]] <- suppressWarnings(as.numeric(df[[cc]]))
  
  # JS: HORSE_DATA
  js_array  <- jsonlite::toJSON(df, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
  js_horses <- paste0("window.HORSE_DATA = ", js_array, ";\n")
  
  # JS: TRACK_STYLE (quote safely via toJSON)
  q <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE)
  js_track <- sprintf(
    "window.TRACK_STYLE = {backgroundTop:%s, backgroundBottom:%s, border:%s};",
    q(backgroundTop), q(backgroundBottom), q(border)
  )
  
  # Combine and write
  js_track_horse <- paste(js_track, js_horses, sep = "\n\n")
  out_path <- file.path(dirname(csv_path), out_filename)
  writeLines(js_track_horse, out_path)
  
  message("✅ JS file saved to: ", out_path)
  invisible(out_path)
}


