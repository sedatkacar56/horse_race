#' Update and merge position values across two CSV files
#'
#' @description
#' `update_positions_by_name()` updates or appends values in a target column 
#' (default `"position"`) of one CSV file (`file_to_change`) using matching values 
#' from another CSV file (`what_to_change`), based on a shared key column 
#' (default `"name"`). 
#' 
#' If the target column is empty (`NA` or ""), the function replaces it 
#' with the new value. If it already has data, the new value is appended.
#'
#' @param pathto_file_to_change Character. Path to the CSV file whose column will be updated.
#' @param pathto_what_to_change Character. Path to the CSV file containing new values.
#' @param column_to_overlap Character. Name of the column used as the key to match rows between files. 
#'   Default is `"name"`.
#' @param column_to_change Character. Name of the column to update or append to. 
#'   Default is `"position"`.
#' @param globalenv_assign_name Character. Name of the object to assign in the global environment 
#'   after updating the file. Default is `"file_to_change"`.
#'
#' @details
#' The function:
#' 1. Reads both CSV files into data frames.
#' 2. Builds a named vector of new values from `what_to_change` using 
#'    `setNames(new_values, key_column)`.
#' 3. Matches by the overlap column and updates/merges the target column.
#' 4. Writes the updated data back to the original CSV file.
#' 5. Assigns the updated data frame to the global environment for immediate access.
#'
#' @return
#' Invisibly returns the updated data frame and writes the changes to disk.
#'
#' @examples
#' \dontrun{
#' # Example: Update positions of horses by name
#' update_positions_by_name(
#'   pathto_file_to_change = "data/horses.csv",
#'   pathto_what_to_change = "data/updated_positions.csv",
#'   column_to_overlap = "name",
#'   column_to_change = "position",
#'   globalenv_assign_name = "horses_updated"
#' )
#' }
#'
#' @export
update_positions_by_name <- function(
    pathto_file_to_change,
    pathto_what_to_change,
    column_to_overlap = "name",
    column_to_change  = "position",
    globalenv_assign_name = "file_to_change",
    replace = TRUE  # <-- NEW: TRUE = replace, FALSE = append
){
  
  force(pathto_file_to_change)
  force(pathto_what_to_change)
  force(column_to_overlap)
  force(column_to_change)
  force(globalenv_assign_name)
  
  # Read primary
  file_to_change <- read.csv(pathto_file_to_change, row.names = 1, stringsAsFactors = FALSE)
  print(colnames(file_to_change))
  
  # Read update file
  what_to_change <- read.csv(pathto_what_to_change, stringsAsFactors = FALSE)
  print(colnames(what_to_change))
  
  # Basic sanity
  stopifnot(column_to_overlap %in% names(file_to_change))
  stopifnot(column_to_change  %in% names(file_to_change))
  stopifnot(column_to_overlap %in% names(what_to_change))
  stopifnot(column_to_change  %in% names(what_to_change))
  
  # Normalize keys
  file_to_change[[column_to_overlap]] <- trimws(file_to_change[[column_to_overlap]])
  what_to_change[[column_to_overlap]] <- trimws(what_to_change[[column_to_overlap]])
  
  # Map new values by key
  new_vals <- setNames(what_to_change[[column_to_change]], what_to_change[[column_to_overlap]])
  
  in_update <- file_to_change[[column_to_overlap]] %in% names(new_vals)
  old <- file_to_change[[column_to_change]][in_update]
  add <- new_vals[file_to_change[[column_to_overlap]][in_update]]
  
  if (replace) {
    # REPLACE mode: just replace all values
    file_to_change[[column_to_change]][in_update] <- add
  } else {
    # APPEND mode: replace empty/NA, else append
    replace_idx <- is.na(old) | old == ""
    old[replace_idx]  <- add[replace_idx]
    old[!replace_idx] <- paste0(old[!replace_idx], add[!replace_idx])
    file_to_change[[column_to_change]][in_update] <- as.character(old)
  }
  
  # Save
  write.csv(file_to_change, pathto_file_to_change, row.names = TRUE, quote = TRUE)
  assign(globalenv_assign_name, file_to_change, envir = .GlobalEnv)
  
  message("✅ Updated ", sum(in_update), " rows in '", column_to_change, "' (replace=", replace, ").")
  invisible(file_to_change)
}