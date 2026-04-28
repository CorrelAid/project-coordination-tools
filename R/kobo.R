create_kobo <- function(url = "kobo.correlaid.org") {
    kobo <- kbtbr::Kobo$new(url)
    kobo
}


get_applications <- function(kobo, survey_id) {
    kobo$get_submissions(survey_id)
}


get_survey_id <- function(kobo, kobo_survey_name) {
    all_surveys <- kobo$get_surveys()
    # get survey id
    survey <- all_surveys %>%
        filter(str_detect(name, kobo_survey_name))
    stopifnot(nrow(survey) == 1)
    return(survey %>% pull(uid))
}