#' Set and Launch Horse Race Parameters
#'
#' This function writes a small JavaScript configuration file (`race_params.js`) 
#' containing global race parameters such as canvas size, world width, lane gap, 
#' and finish line distance. It then automatically opens the main race HTML page 
#' (e.g., `deneme.html`) in your default browser.
#'
#' @param ww Numeric. World width (the total horizontal distance of the track in pixels).  
#'            Default is 5000.
#' @param fl Numeric. Finish line position (in pixels from start).  
#'            Default is 4500.
#' @param cw Numeric. Canvas width in pixels. Default is 1200.
#' @param ch Numeric. Canvas height in pixels. Default is 600.
#' @param lg Numeric. Lane gap (vertical spacing between horses) in pixels. Default is 10.
#' @param lo Numeric. Lane offset (top padding before first lane) in pixels. Default is 100.
#'
#' @details
#' This function creates a JavaScript file at:
#'   `C:/Users/skacar/Documents/horse_race/race_params.js`
#'
#' The file defines a global JavaScript object:
#' ```
#' window.RACE_PARAMS = {
#'   cw: <canvas width>,
#'   ch: <canvas height>,
#'   ww: <world width>,
#'   lg: <lane gap>,
#'   lo: <lane offset>,
#'   fl: <finish line>
#' };
#' ```
#'
#' Your HTML file (e.g. `deneme.html`) should include this script
#' **before the main race script**, like:
#' ```html
#' <script src="race_params.js"></script>
#' <script src="main_race.js"></script>
#' ```
#' so that JavaScript can read `window.RACE_PARAMS` values dynamically.
#'
#' @examples
#' # Set a long track and open the HTML page
#' set_race_params(ww = 30000, fl = 25000)
#'
#' @return Invisibly writes `race_params.js` and opens the race HTML file.
#' @export
set_race_params <- function(html_name = "deneme_control_canvas2", 
                            ww = 5000, fl = 4500, cw = 1200, ch = 600, lg = 10, lo = 100
) {
  # Write simple JS file
  js_config <- sprintf(
    "window.RACE_PARAMS = {cw:%d, ch:%d, ww:%d, lg:%d, lo:%d, fl:%d};",
    cw, ch, ww, lg, lo, fl
  )
  
  writeLines(js_config, "C:/Users/skacar/Documents/horse_race/race_params.js")
  
  cat("✅ Race parameters saved!\n")
  cat("   Opening race with ww =", ww, "fl =", fl, "\n")
  
  shell.exec(paste0("C:/Users/skacar/Documents/horse_race/", html_name, ".html"))
}
