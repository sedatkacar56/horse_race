#' Compare Two HTML Files Line by Line
#'
#' This function compares the content of two HTML files located in the same directory 
#' and displays a color-coded difference (diff) output in the R console.
#'
#' @param first_html Character string. The base name (without `.html` extension) 
#' of the first HTML file to compare.
#' @param second_html Character string. The base name (without `.html` extension) 
#' of the second HTML file to compare.
#' @param directory Character string. The directory path where both HTML files 
#' are located. Defaults to `"C:/Users/skacar/Documents/horse_race"`.
#'
#' @details 
#' The function reads both HTML files line by line and compares them using 
#' the \code{diffChr()} function from the \pkg{diffobj} package. 
#' It displays any line-by-line differences in color, similar to a Git-style diff.
#'
#' By default, the diff output is shown page by page (\code{pager = "on"}). 
#' You can change this to \code{pager = "off"} inside the function if you prefer 
#' to print all differences directly in the console.
#'
#' @return 
#' Prints the differences between the two HTML files to the console. 
#' It does not return an R object.
#'
#' @examples 
#' \dontrun{
#' html_difference("index_lane_shifting_acallout", "index_lane_shifting")
#' }
#'
#' @seealso \code{\link[diffobj]{diffChr}}, \code{\link[base]{readLines}}
#'
#' @export
html_difference <- function(first_html, second_html, 
                            directory = "C:/Users/skacar/Documents/horse_race"){

f1 <- file.path(directory, paste0(first_html,".html"))
f2 <- file.path(directory, paste0(second_html,".html"))
a <- readLines(f1, warn = FALSE)
b <- readLines(f2, warn = FALSE)
diffobj::diffChr(a, b, pager = "on")
}

