save_wide <- function(demographics, other_quali, file) {
    wide <- demographics %>%
        left_join(other_quali, by = "applicant_id") %>%
        dplyr::select(
            applicant_id,
            gender,
            first_name,
            last_name,
            starts_with("motivation"),
            starts_with("past_applications"),
            team_coordinator_tasks,
            d4gv_participation
        ) %>%
        arrange(applicant_id)
    wide %>% readr::write_csv(file)
    file
}


save_ratings <- function(ratings, file) {
    ratings %>%
        dplyr::select(
            applicant_id,
            question,
            skill,
            rating,
            rating_num
        ) %>%
        arrange(applicant_id) %>%
        readr::write_csv(file)
    file
}


save_gs_upload <- function(roles_skills, demographics, other_quali, file) {
    roles_skills %>%
        left_join(demographics, by = "applicant_id") %>%
        left_join(other_quali, by = "applicant_id") %>%
        dplyr::select(
            applicant_id,
            gender,
            project_id,
            project_role,
            past_applications,
            pa_score,
            skills_mean_self = mean_skills
        ) %>%
        arrange(gender, applicant_id, project_id, project_role) %>%
        readr::write_csv(file)
    file
}


read_role_profiles <- function(file) {
    readr::read_csv(file)
}

save_role_profiles <- function(role_profiles_long, folder = FOLDER) {
    path <- here::here(folder, "data/role_profiles_long.csv")
    role_profiles_long %>%
        readr::write_csv(path)
    return(path)
}