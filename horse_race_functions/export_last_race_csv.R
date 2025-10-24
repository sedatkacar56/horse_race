#' Export last race to CSV and optionally update the main horses table
#'
#' Reads a JavaScript file that defines \code{window.RACE_HISTORY_DATA = {...}},
#' evaluates it with a JS engine, extracts a race (by default the "last" race,
#' i.e., the file's \code{raceNumber} or the max \code{raceNum}), writes a CSV
#' with selected columns (default: \code{name, position}), and—if requested—
#' updates the main horses CSV by replacing/appending the \code{position}
#' column for matching \code{name}s.
#'
#' @param js_path Character. Path to the race history JS file (the file that
#'   assigns to \code{window.RACE_HISTORY_DATA}). Default:
#'   \code{"C:/Users/skacar/Downloads/racehistory.js"}.
#' @param out_csv Character. Path of the CSV to write containing the selected
#'   columns from the chosen race. Default:
#'   \code{"C:/Users/skacar/Documents/horse_race/race_last.csv"}.
#' @param main_csv Character. Path to the main horses CSV that contains at least
#'   the columns \code{name} and \code{position}. Used only when
#'   \code{update_main = TRUE}. Default:
#'   \code{"C:/Users/skacar/Documents/horse_race/horses.csv"}.
#' @param cols Character vector. The columns to include in \code{out_csv}.
#'   Valid options are any of \code{name}, \code{position}, \code{lane},
#'   \code{color}. Default: \code{c("name","position")}.
#' @param race_num Integer or \code{NULL}. If \code{NULL}, the function uses the
#'   top-level \code{raceNumber} in the JS file; if that is absent, it falls
#'   back to the maximum \code{raceNum} present in \code{races}. Supply a value
#'   to export a specific race.
#' @param update_main Logical. If \code{TRUE}, the function reads \code{main_csv}
#'   and updates the \code{position} column for rows whose \code{name} appears in
#'   the exported race. If an existing \code{position} is \code{NA} or empty, it
#'   is replaced; otherwise, the new position is appended as a string to the
#'   right (e.g., \code{2 -> "23"}). Default: \code{TRUE}.
#'
#' @details
#' \strong{Processing steps}
#' \enumerate{
#'   \item Reads the JS file and evaluates it with the \pkg{V8} engine to obtain
#'         a valid JSON string for \code{window.RACE_HISTORY_DATA}.
#'   \item Parses JSON with \pkg{jsonlite}.
#'   \item Selects the race indicated by \code{race_num}, or else the file's
#'         \code{raceNumber}, or else the maximum \code{raceNum}.
#'   \item Flattens the race \code{results} into a data frame and writes
#'         \code{out_csv} containing only \code{cols}.
#'   \item If \code{update_main = TRUE}, reads \code{main_csv}, ensures
#'         \code{name}/\code{position} exist, and updates \code{position}:
#'         \itemize{
#'           \item If current \code{position} is \code{NA} or \code{""}, it is
#'                 replaced by the new value.
#'           \item Otherwise, the new value is appended to the right as text
#'                 (e.g., \code{2} and new \code{3} becomes \code{"23"}).
#'         }
#'         The updated table is written back to \code{main_csv} and also assigned
#'         to the global environment as \code{horses}.
#' }
#'
#' \strong{Notes}
#' \itemize{
#'   \item \code{main_csv} should include a literal \code{name} column. Avoid
#'         reading it with \code{row.names=1} if that would consume the
#'         \code{name} column as row names.
#'   \item When writing CSVs, consider \code{row.names = FALSE} to prevent an
#'         extra index column in the file.
#' }
#'
#' @return Invisibly returns the data frame written to \code{out_csv} (i.e., the
#'   selected columns for the chosen race).
#'
#' @examples
#' \dontrun{
#' # 1) Export the last race (by raceNumber) to name + position:
#' export_last_race_csv()
#'
#' # 2) Export race 17 specifically, write all fields, but do not update main:
#' export_last_race_csv(
#'   race_num = 17,
#'   cols = c("name","position","lane","color"),
#'   update_main = FALSE
#' )
#'
#' # 3) Use custom paths:
#' export_last_race_csv(
#'   js_path  = "C:/Users/skacar/Documents/horse_race/RACE_HISTORY_DATA.js",
#'   out_csv  = "C:/Users/skacar/Documents/horse_race/last_race_positions.csv",
#'   main_csv = "C:/Users/skacar/Documents/horse_race/horses.csv"
#' )
#' }
#'
#' @seealso \code{\link[V8]{v8}}, \code{\link[jsonlite]{fromJSON}}
#' @export
export_last_race_csv <- function(js_path = "C:/Users/skacar/Downloads/racehistory.js",
                                 out_csv = "C:/Users/skacar/Documents/horse_race/race_last.csv",
                                 main_csv = "C:/Users/skacar/Documents/horse_race/horses.csv",
                                 cols = c("name","position"),
                                 race_num = NULL,
                                 update_main = TRUE) {
  if (!requireNamespace("V8", quietly = TRUE)) stop("install.packages('V8')")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("install.packages('jsonlite')")
  
  # ---- 1) Read/eval JS and parse ----
  js_text <- paste(readLines(js_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  program <- paste0("var window = {};\n", js_text, "\n", "JSON.stringify(window.RACE_HISTORY_DATA);")
  ctx <- V8::v8()
  json_str <- ctx$eval(program)
  obj <- jsonlite::fromJSON(json_str, simplifyVector = FALSE)
  
  # ---- 2) Choose race to export ----
  races <- obj$races
  if (is.null(races) || !length(races)) stop("No races found in file.")
  
  if (is.null(race_num)) {
    race_num <- obj$raceNumber
    if (is.null(race_num)) {
      race_nums <- vapply(races, function(r) r$raceNum %||% NA_integer_, integer(1))
      race_num <- max(race_nums, na.rm = TRUE)
    }
  }
  
  pick <- NULL
  for (r in races) {
    if (!is.null(r$raceNum) && identical(as.integer(r$raceNum), as.integer(race_num))) {
      pick <- r; break
    }
  }
  if (is.null(pick)) stop("Race number ", race_num, " not found.")
  res <- pick$results
  if (is.null(res) || !length(res)) stop("Selected race has no results.")
  
  # ---- 3) Flatten & write CSV (name, position by default) ----
  df <- data.frame(
    name     = vapply(res, function(x) x$name     %||% NA_character_, character(1)),
    position = vapply(res, function(x) x$position %||% NA_integer_,   integer(1)),
    lane     = vapply(res, function(x) x$lane     %||% NA_integer_,   integer(1)),
    color    = vapply(res, function(x) x$color    %||% NA_character_, character(1)),
    stringsAsFactors = FALSE
  )
  keep <- intersect(cols, names(df))
  if (!length(keep)) stop("None of the requested columns present: ", paste(cols, collapse = ", "))
  df_out <- df[, keep, drop = FALSE]
  write.csv(df_out, out_csv, row.names = FALSE)
  
  # ---- 4) Update main horses.csv (optional) ----
  if (isTRUE(update_main)) {
    horses <- read.csv(main_csv, stringsAsFactors = FALSE, row.names = 1)
    # sanity: ensure columns exist
    stopifnot("name" %in% names(horses))
    stopifnot("position" %in% names(horses))
    # ensure types
    horses$position <- as.character(horses$position)
    df_out$position <- as.character(df_out$position)
    
    # Build a named vector of new positions by name
    new_pos <- setNames(df_out$position, df_out$name)
    
    # For names that appear in horses, update position:
    in_update <- horses$name %in% names(new_pos)
    old <- horses$position[in_update]
    add <- new_pos[ horses$name[in_update] ]  # aligned by order
    
    # Replace if NA/empty, else append
    replace_idx <- is.na(old) | old == ""
    old[replace_idx] <- add[replace_idx]
    old[!replace_idx] <- paste0(old[!replace_idx], add[!replace_idx])
    
    horses$position[in_update] <- old
    
    # Save & expose in global env
    write.csv(horses, main_csv)
    assign("horses", horses, envir = .GlobalEnv)
  }
  
  # ---- 5) Optional: delete temporary race_last.csv ----
  if (file.exists(js_path)) {
    file.remove(js_path)
    message("🧹 Deleted temporary file: ", js_path)
  }
  
  
  message("✅ Wrote ", nrow(df_out), " rows to: ", out_csv, " (race ", race_num, ").",
          if (isTRUE(update_main)) " Main horses.csv updated." else "")
  invisible(df_out)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

