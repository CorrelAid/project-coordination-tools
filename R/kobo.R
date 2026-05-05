create_kobo <- function(url = "kobo.correlaid.org") {
    kobo <- kbtbr::Kobo$new(url)
    kobo
}


get_applications <- function(kobo, survey_id) {
    kobo$get_submissions(survey_id)
}

