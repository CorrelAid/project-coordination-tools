
make_report <- function(
    project_id,
    folder,
    template_report,
    template_single,
    by_role = FALSE,
    anon = TRUE
) {
    output_file <- ifelse(by_role, sprintf("%s-by-role.html", project_id), sprintf("%s-by-appl.html", project_id))
    # knit report
    rmarkdown::render(
        here::here(template_report),
        output_dir = folder,
        output_file = output_file,
        params = list(
            project_id = project_id,
            folder = folder,
            by_role = by_role,
            anon = anon
        )
    )
}
