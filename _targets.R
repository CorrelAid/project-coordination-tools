library(targets)
library(dotenv)
library(magrittr)

# load all custom functions
tar_source("R")

FOLDER <- here::here("projects", "example")
LOAD_SELECTED <- FALSE
LOAD_FROM_KOBO <- TRUE

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
        KOBO_SURVEY_MATCH = Sys.getenv("PROJECT_IDS"),
        KOBO_SURVEY_ID = Sys.getenv("KOBO_SURVEY_ID"),
        GSHEET = Sys.getenv("GSHEET"),
        LOAD_FROM_KOBO = LOAD_FROM_KOBO,
        LOAD_SELECTED = LOAD_SELECTED
        
      )
    },
    cue = tar_cue(mode = "always")  # always read
  ),
  tar_target(kobo, create_kobo()),


  # ROLE PROFILES FROM XLSFORM GOOGLE SHEETS
  tar_target(
    role_profiles_downloaded,
    here::here(FOLDER, "data", "role_profiles.csv"),
    format = "file"
  ),
  tar_target(role_profiles_wide, read_role_profiles(role_profiles_downloaded)),
  tar_target(role_profiles_long, make_role_profiles_long(role_profiles_wide)),
  tar_target(
    saved_role_profiles,
    save_role_profiles(role_profiles_long),
    format = "file"
  ),

  # LOAD DATA FROM KOBO AND INITIAL CLEANING
  tar_target(applications_raw, get_applications(kobo, config$KOBO_SURVEY_ID)),
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
    saved_gs_upload,
    command = save_gs_upload(
      roles_skills,
      demographics,
      other_quali,
      here::here(FOLDER, "data", "gs_upload.csv")
    ), 
    format = "file"
  ),
  tar_target(saved_wide, save_wide(demographics, other_quali, here::here(FOLDER, "data", "wide.csv")),
             format = "file"),
  tar_target(
    saved_ratings,
    save_ratings(skill_ratings_long, here::here(FOLDER, "data", "ratings.csv")),
    format = "file"
  ),


  tar_target(
    mapping,
    {
      path <- here::here(FOLDER, "data", "mapping.csv")
      demographics %>% select(-gender) %>% readr::write_csv(path)
      return(path)
    },
    format = "file"
  ),  
  # REPORTS
  # anonymized
  tar_target(
    template_single,
    here::here("templates", "template_application_single.Rmd"),
    format = "file"
  ),
  tar_target(
    template_application_report,
    here::here("templates", "template_application_report.Rmd"),
    format = "file"
  ),
  tar_target(
    template_selected_report,
    here::here("templates", "template_selected_report.Rmd"),
    format = "file"
  ),

  tar_target(
    report_anon_by_appl,
    command = make_application_report(config$PROJECT_IDS, FOLDER, template_application_report, by_role = FALSE),
    format = "file"
  ),
  tar_target(
    report_anon_by_role,
    command = make_application_report(config$PROJECT_IDS, FOLDER, template_application_report, by_role = TRUE),
    format = "file"
  ),

  # selected team with names
  tar_target(
    selected,
    {
      path <- here::here(FOLDER, "data", "selected.csv")
      load_selected(config$GSHEET) %>% readr::write_csv(path)
      return(path)
    },
    format = "file",
    cue = tar_cue(mode = ifelse(LOAD_SELECTED, "always", "thorough"))
  ),
  tar_target(
    report_selected_team,
    command = make_selected_report(config$PROJECT_IDS, FOLDER, template_selected_report),
    format = "file"
  )
)
