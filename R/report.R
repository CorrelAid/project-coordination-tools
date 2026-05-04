
make_report <- function(
    project_id,
    folder,
    template_report,
    output_file,
    ...
) {

    # collect optional params
    extra_params <- list(...)
    
    # default params
    base_params <- list(
      project_id = project_id,
      folder = folder
    )
    
    # merge them
    report_params <- c(base_params, extra_params)
    
    # knit report
    rmarkdown::render(
        here::here(template_report),
        output_dir = folder,
        output_file = output_file,
        params = report_params
    )
}

make_application_report <- function(project_id,
                                    folder, template_report, by_role = FALSE) {
  output_file <- ifelse(by_role, sprintf("%s-by-role.html", project_id), sprintf("%s-by-appl.html", project_id))
  
  make_report(project_id, folder, template_report, output_file, by_role = by_role)
}

make_selected_report <- function(project_id,
                                    folder, template_report, by_role = FALSE) {
  output_file <- ifelse(sprintf("%s-selected.html", project_id))

  make_report(project_id, folder, template_report, output_file)
}