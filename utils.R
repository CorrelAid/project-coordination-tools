# we used to have another format for the project id: WEL-03-2022
# this was then changed to make sorting easier. the following functions deals with that
id_path <- function (project_id_surveymonkey)
{
  pattern <- "([:upper:]{3})-(\\d{2})-(\\d{4})"
  prefix <- stringr::str_replace(project_id_surveymonkey, pattern,
                                 "\\1")
  month <- stringr::str_replace(project_id_surveymonkey, pattern,
                                "\\2")
  year <- stringr::str_replace(project_id_surveymonkey, pattern,
                               "\\3")
  paste(year, month, prefix, sep = "-")
}

unify_project_id_formats <- function (char_vec)
{
  regex_old <- "\\w{3}-\\d{2}-\\d{4}"
  ifelse(stringr::str_detect(char_vec, regex_old),
         id_path(char_vec),
         char_vec)
}


extract_ids_from_kobo_columnnames <- function (columnnames)
{
  regex_old <- "\\w{3}_\\d{2}_\\d{4}"
  regex_new <- "\\d{4}_\\d{2}_\\w{3}"
  extracted <-
    columnnames %>% stringr::str_extract(glue::glue("{regex_old}|{regex_new}")) %>%
    stringr::str_replace_all("_", "-") %>% stringr::str_to_upper() %>%
    stringr::str_trim()
  unify_project_id_formats(extracted)
}
