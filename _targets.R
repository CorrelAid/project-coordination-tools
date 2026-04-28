library(targets)
library(dotenv)
library(magrittr)

# load all custom functions
tar_source("R")

FOLDER <- here::here("projects", "2026-05-MIC")

tar_option_set(
  packages = c(
    "tidyr",
    "dplyr",
    "readr",
    "stringr", #tidyverse suite
    "kbtbr"
  )
)

list(
  # SETUP
  tar_target(
    config,
    {
      dotenv::load_dot_env(here::here(FOLDER, ".env"))
      list(
        PROJECT_IDS = Sys.getenv("PROJECT_IDS") %>% stringr::str_split_1(","),
        KOBO_SURVEY_NAME = sprintf("Project Application Form: %s", Sys.getenv("PROJECT_IDS") %>% stringr::str_split_1(","))
      )
    },
    cue = tar_cue(mode = "always")  # always read
  ),
  tar_target(kobo, create_kobo()),


  # ROLE PROFILES FROM XLSFORM GOOGLE SHEETS
  tar_target(
    file,
    here::here(FOLDER, "data", "role_profiles.csv"),
    format = "file"
  ),
  tar_target(role_profiles_wide, read_role_profiles(file)),
  tar_target(role_profiles_long, make_role_profiles_long(role_profiles_wide)),
  tar_target(
    saved_role_profiles,
    save_role_profiles(role_profiles_long),
    format = "file"
  ),

  # LOAD DATA FROM KOBO AND INITIAL CLEANING
  tar_target(survey_id, get_survey_id(kobo, config$KOBO_SURVEY_NAME)),
  tar_target(applications_raw, get_applications(kobo, survey_id)),
  tar_target(applications_clean, clean_applications_raw(applications_raw)),

  # EXTRACT DIFFERENT DATASETS FOR DATA WRANGLING
  # mostly "longifying"
  tar_target(
    project_roles_choices_long,
    make_project_roles_long(applications_clean)
  ),
  tar_target(skill_ratings_long, make_skill_ratings_long(applications_clean)),
  tar_target(demographics, make_demographics(applications_clean)),
  tar_target(other_quali, make_other_qualifications(applications_clean)),

  # MATCH RELEVANT SKILLS FOR EACH ROLE
  tar_target(
    roles_skills,
    calculate_skill_rating_per_role(
      project_roles_choices_long,
      role_profiles_long,
      skill_ratings_long
    )
  ),

  # JOIN + SAVE
  tar_target(
    gs_upload_file,
    here::here(FOLDER, "data", "gs_upload.csv"),
    format = "file"
  ),
  tar_target(
    saved_gs_upload,
    command = save_gs_upload(
      roles_skills,
      demographics,
      other_quali,
      gs_upload_file
    )
  ),
  tar_target(
    wide_file,
    here::here(FOLDER, "data", "wide.csv"),
    format = "file"
  ),
  tar_target(saved_wide, save_wide(demographics, other_quali, wide_file)),
  tar_target(
    skill_ratings_long_file,
    here::here(FOLDER, "data", "ratings.csv"),
    format = "file"
  ),
  tar_target(
    saved_ratings,
    save_ratings(skill_ratings_long, skill_ratings_long_file)
  ),
  # todo mapping

  # REPORTS
  # anonymized
  tar_target(
    template_single,
    here::here("templates", "template_application_single.Rmd"),
    format = "file"
  ),
    tar_target(
    template_report,
    here::here("templates", "template_application_report.Rmd"),
    format = "file"
  ),

  tar_target(
    report_anon_by_appl,
    command = make_report(config$PROJECT_IDS, FOLDER, template_report, template_single, by_role = FALSE, anon = TRUE),
    format = "file"
  ),
  tar_target(
    report_anon_by_role,
    command = make_report(config$PROJECT_IDS, FOLDER, template_report, template_single, by_role = TRUE, anon = TRUE),
    format = "file"
  )

  # selected team with names
)
