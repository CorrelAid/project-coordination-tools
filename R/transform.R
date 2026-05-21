clean_applications_raw <- function(applications_raw) {
    applications_clean <- applications_raw %>%
        dplyr::rename(applicant_id = `_id`) %>% # id column
        dplyr::select(-starts_with("_"), starts_with("formhub")) # drop all columns starting with "_"

    # remove all group* from column names except rating
    colnames(applications_clean) <- stringr::str_replace_all(
        colnames(applications_clean),
        "group_roles+?/(.+?)$",
        "\\1"
    )

    colnames(applications_clean) <- stringr::str_replace_all(
        colnames(applications_clean),
        "demographics_.+?/(.+?)$",
        "\\1"
    )
    colnames(applications_clean) <- stringr::str_replace_all(
        colnames(applications_clean),
        "skills/(.+?)$",
        "\\1"
    )
    colnames(applications_clean) <- stringr::str_replace_all(
        colnames(applications_clean),
        "demographics/(.+?)$",
        "\\1"
    )
    colnames(applications_clean) <- stringr::str_replace_all(
        colnames(applications_clean),
        "projectyou/(.+?)$",
        "\\1"
    )
    colnames(applications_clean) <- stringr::str_replace_all(
        colnames(applications_clean),
        "d4gv/(.+?)$",
        "\\1"
    )

    return(applications_clean)
}

make_project_roles_long <- function(applications) {
    project_roles_df <- applications %>%
        select(applicant_id, starts_with("project_role")) %>% # for each project, there is one question
        tidyr::gather(
            starts_with("project_role"),
            key = "project_id",
            value = "project_role"
        ) %>%
        filter(!is.na(project_role)) %>%
        mutate(project_id = str_remove_all(project_id, "project_role_")) %>%
        arrange(applicant_id, project_id)

    # for cross checks
    applied_to_df <- applications %>%
        tidyr::separate_rows(project_id, sep = " ") %>%
        select(applicant_id, project_id) %>%
        arrange(applicant_id, project_id)

    # this should always be the same..
    # unless someone chose a role for a project and then unticked the project in the "what do you want to apply for" question
    stopifnot(nrow(applied_to_df) == nrow(project_roles_df))
    stopifnot(applied_to_df$applicant_id == project_roles_df$applicant_id)
    stopifnot(applied_to_df$project_id == project_roles_df$project_id)

    # but people can apply not only to multiple projects
    # but to to multiple roles per project -> make even longer
    # this is our mapping for google sheets
    project_roles_df %>%
        tidyr::separate_rows(project_role, sep = " ")
}


make_skill_ratings_long <- function(applications) {
    rating_df <- applications %>%
        dplyr::select(applicant_id, starts_with("rating")) %>%
        tidyr::gather(starts_with("rating"), key = "what", value = "rating") %>%
        dplyr::filter(!is.na(rating) & !str_detect(what, "_header")) %>%
        dplyr::mutate(what = str_remove_all(what, "rating_")) %>%
        tidyr::separate(what, into = c("question", "skill"), sep = "/")

    # mapping
    rating_mapping <- tibble::tribble(
        ~rating    , ~rating_num ,
        "beginner" ,           1 ,
        "user"     ,           2 ,
        "advanced" ,           3 ,
        "expert"   ,           4
    )
    rating_df <- rating_df %>%
        left_join(rating_mapping)

    return(rating_df)
}


make_demographics <- function(applications) {
    if ("gender_self_identification" %in% colnames(applications)) {
        applications <- applications %>%
            dplyr::mutate(
                gender = dplyr::if_else(
                    gender == "self_identification",
                    NA_character_,
                    gender
                )
            )

        applications$gender <- dplyr::coalesce(
            applications$gender,
            applications$gender_self_identification
        )
    }
    demographics_info_df <- applications %>%
        dplyr::select(
            applicant_id,
            first_name,
            last_name,
            email,
            gender
        )
    return(demographics_info_df)
}

make_other_qualifications <- function(applications) {
    other_df <- applications %>%
        dplyr::select(
            applicant_id,
            dplyr::contains("motivation"),
            dplyr::contains("past_"),
            german_skills,
            team_coordinator_tasks,
            d4gv_participation
        ) %>%
        mutate(
            pa_score = case_when(
                past_applications == "successful" ~ 0,
                past_applications == "not_successful" ~ 2,
                past_applications == "first_application" ~ 1
            ),
            d4gv_count = if_else(is.na(d4gv_participation), 0, stringr::str_count(d4gv_participation, " ") + 1)
        )
    return(other_df)
}

get_relevant_skill_ratings_for_project_role <- function(
    skill_ratings,
    role_profiles,
    project_id,
    project_role
) {
    role_profile <- role_profiles %>%
        filter(
            project_id == .env$project_id,
            role == .env$project_role
        ) %>%
        rename(project_role = role)

    skill_ratings %>%
        filter(
            skill %in% role_profile$skill
        ) %>%
        select(-question) %>%
        right_join(role_profile, by = "skill")
}


calculate_aggregated_skill_ratings <- function(
    role_choices,
    role_profiles,
    skill_ratings
) {
    purrr::pmap_dfr(
        list(
            role_choices$applicant_id,
            role_choices$project_id,
            role_choices$project_role
        ),
        function(applicant_id, project_id, project_role) {
            skill_ratings %>% 
                filter(applicant_id == .env$applicant_id) %>% 
                get_relevant_skill_ratings_for_project_role(role_profiles, project_id, project_role) %>% 
                group_by(applicant_id, project_id, project_role, priority) %>%
                summarize(
                    mean_rating = round(mean(rating_num, na.rm = TRUE), 2),
                    max_score = n() * 4,
                    sum_score = sum(rating_num, na.rm = TRUE),
                    score = round(sum_score / max_score * 5, 2) # normalize to 0-5 to align with motivation scale --> is it basically the mean rescaled to 0 - 5?
                ) %>%
                pivot_wider(
                    names_from = priority,
                    values_from = c(mean_rating, max_score, sum_score, score)
                )
        }
    )
}


make_role_profiles_long <- function(role_profiles_wide) {
    role_profiles_wide %>%
        select(
            project_id,
            role = name,
            ends_with(c("_core", "_nicetohave"))
        ) %>%
        gather(
            ends_with(c("_core", "_nicetohave")),
            key = "question",
            value = "skill"
        ) %>%
        tidyr::separate(question, c("question", "priority"), sep = "_") %>%
        filter(!is.na(skill)) %>%
        separate_rows(skill, sep = ",") %>%
        mutate(skill = str_trim(skill))
}


build_wide <- function(demographics, other_quali) {
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
            starts_with("d4gv"),
            german_skills
        ) %>%
        arrange(applicant_id)
    wide
}


build_gs_upload <- function(roles_skills, demographics, other_quali) {
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
            d4gv_count,
            starts_with("score"),
            german_skills
        ) %>%
        arrange(gender, applicant_id, project_id, project_role)
}

build_report_data <- function(roles_skills, demographics, other_quali) {
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
            ends_with("nicetohave"),
            ends_with("core")
        ) %>%
        arrange(gender, applicant_id, project_id, project_role)
}