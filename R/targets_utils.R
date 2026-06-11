reload_selected <- function() {
  targets::tar_invalidate(dplyr::starts_with("selected"))
  targets::tar_make(dplyr::starts_with("selected"))
  targets::tar_invalidate(report_teams)
  targets::tar_make(report_teams)
  
}

