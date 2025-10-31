#' Export a Horse Race from JS to CSV and Optionally Update Main Table
#'
#' Extracts a specified (or most recent) horse race from a JavaScript file defining
#' `window.RACE_HISTORY_DATA`, and writes selected columns (e.g., name, position) to a CSV file.
#' Optionally updates a main horses table by modifying the `position` values for matching names.
#'
#' @param js_path Character. Path to the JavaScript file (default: "C:/Users/skacar/Downloads/racehistory.js").
#' @param out_csv Character. Output path for the extracted race CSV (default: "C:/Users/skacar/Documents/horse_race/race_last.csv").
#' @param main_csv Character. Path to the main horses table CSV (default: "C:/Users/skacar/Documents/horse_race/horses.csv").
#' @param cols Character vector. Which columns to export (options: "name", "position", "lane", "color"). Default: c("name", "position").
#' @param race_num Integer or NULL. Specific race number to extract. If NULL, auto-selects based on JS metadata.
#' @param update_main Logical. If TRUE, updates the main horses table by appending or replacing `position` values. Default: TRUE.
#'
#' @return Invisibly returns a data frame of the extracted race with selected columns.
#'
#' @details
#' Reads a JS file and uses the V8 engine to evaluate `window.RACE_HISTORY_DATA`.
#' Then, the selected race is flattened to a data frame and written to `out_csv`.
#' If `update_main = TRUE`, the function modifies `position` values in `main_csv` for matching names.
#' Existing `position`s are replaced if empty/NA, or appended otherwise.
#'
#' The input JS file is optionally deleted after processing.
#'
#' @examples
#' export_last_race_csv()
#' export_last_race_csv(race_num = 3, cols = c("name", "position", "lane"), update_main = FALSE)
#' export_last_race_csv(js_path = "data/RACE_HISTORY_DATA.js", out_csv = "data/race_out.csv")
#'
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
  js_text <- paste(readLines(js_path), collapse = "\n")#i discarded warn = F and encoding = UTF-8
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
  
  
  write.csv(df_out, out_csv, row.names = FALSE)#output
  
  
  # ---- 4) Update main horses.csv (optional) ----
  if (isTRUE(update_main)) {
    horses <- read.csv(main_csv, row.names = 1)
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

#' In this version u also add handicap points
#'
#' @export
export_last_race_csv_try <- function(js_path = "C:/Users/skacar/Downloads/racehistory.js",
                                     out_csv = "C:/Users/skacar/Documents/horse_race/race_last.csv",
                                     main_csv = "C:/Users/skacar/Documents/horse_race/horses.csv",
                                     cols = c("name","position", "handicap"),
                                     race_num = NULL,
                                     update_main = TRUE) {
  if (!requireNamespace("V8", quietly = TRUE)) stop("install.packages('V8')")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("install.packages('jsonlite')")
  
  # ---- 1) Read/eval JS and parse ----
  js_text <- paste(readLines(js_path), collapse = "\n")#i discarded warn = F and encoding = UTF-8
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
    handicap     = vapply(res, function(x) x$handicap     %||% NA_integer_,   integer(1)),
    
    stringsAsFactors = FALSE
  )
  keep <- intersect(cols, names(df))
  if (!length(keep)) stop("None of the requested columns present: ", paste(cols, collapse = ", "))
  df_out <- df[, keep, drop = FALSE]
  point <- max(df_out$position) -1
  
  df_out$handicap <- df_out$handicap + (max(df_out$position) - df_out$position)
  
    write.csv(df_out, out_csv, row.names = FALSE)#output

  horses <- read.csv(main_csv, row.names = 1)
  write.csv(horses, "horses1.csv")

  
  update_positions_by_name(pathto_file_to_change = main_csv,
                           pathto_what_to_change = out_csv, 
                           column_to_overlap = "name", column_to_change = "handicap", 
                           globalenv_assign_name = "horses",
                           replace = TRUE)
  
  
  #CHANGE THE HORSES
  # Read the names you want to update
  target_names <- df_out$name
  horses <- read.csv(main_csv, row.names = 1)
  
    # Add 1 to hndp_race where name matches
  horses$hndp_race[horses$name %in% target_names] <- horses$hndp_race[horses$name %in% target_names] + 1
  horses$aver_hndp <- horses$handicap / horses$hndp_race
  write.csv(horses, main_csv)
  
  # ---- 4) Update main horses.csv (optional) ----
  if (isTRUE(update_main)) {
    update_positions_by_name(pathto_file_to_change = main_csv,
                             pathto_what_to_change = out_csv, 
                             column_to_overlap = "name", column_to_change = "position", 
                             globalenv_assign_name = "horses",
                             replace = FALSE)
    
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


