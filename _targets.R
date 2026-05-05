library(targets)
library(tarchetypes)
library(here)
library(stringr)

tar_option_set(
  packages = c(
    "dplyr",
    "tidyr",
    "readr",
    "stringr",
    "kbtbr"
  )
)

# load your functions
tar_source("R")

FOLDER <- here::here("projects", "example")

list(

  # -----------------------
  # CONFIG
  # -----------------------
  tar_target(
    config,
    {
      dotenv::load_dot_env(here::here(FOLDER, ".env"))
      list(
        project_ids = stringr::str_split_1(Sys.getenv("PROJECT_IDS"), ","),
        survey_id   = Sys.getenv("KOBO_SURVEY_ID"),
        gsheet      = Sys.getenv("GSHEET")
      )
    }
  ),

  # -----------------------
  # INPUT DATA
  # -----------------------
  tar_target(
    kobo,
    create_kobo()
  ),

  tar_target(
    role_profiles_file,
    here::here(FOLDER, "data", "role_profiles.csv"),
    format = "file"
  ),

  tar_target(
    role_profiles_long,
    role_profiles_file |>
      readr::read_csv() |>
      make_role_profiles_long()
  ),

  tar_target(
    applications_raw,
    get_applications(kobo, config$survey_id)
  ),

  tar_target(
    applications_clean,
    clean_applications_raw(applications_raw)
  ),

  # -----------------------
  # DERIVED DATA
  # -----------------------
  tar_target(
    applicant_project_roles_df,
    make_project_roles_long(applications_clean)
  ),

  tar_target(
    applicant_skill_ratings_df,
    make_skill_ratings_long(applications_clean)
  ),

  tar_target(
    applicant_demographics_df,
    make_demographics(applications_clean)
  ),

  tar_target(
    applicant_other_quali_df,
    make_other_qualifications(applications_clean)
  ),

  tar_target(
    applicant_project_roles_avg_skill_rating_df,
    calculate_skill_rating_per_role(
      applicant_project_roles_df,
      role_profiles_long,
      applicant_skill_ratings_df
    )
  ),

  # -----------------------
  # FINAL DATA PRODUCTS (OBJECTS)
  # -----------------------
  tar_target(
    gs_upload_df,
    build_gs_upload(
      applicant_project_roles_avg_skill_rating_df,
      applicant_demographics_df,
      applicant_other_quali_df
    )
  ),

  tar_target(
    wide_df,
    build_wide(
      applicant_demographics_df,
      applicant_other_quali_df
    )
  ),

  tar_target(
    mapping_df,
    applicant_demographics_df |> dplyr::select(-gender)
  ),

  # -----------------------
  # FILE OUTPUTS
  # -----------------------
  tar_target(
    file_applicant_project_roles,
    write_csv_target(gs_upload_df, here::here(FOLDER, "data", "applicant_project_roles.csv")),
    format = "file"
  ),

  tar_target(
    file_applicant_wide,
    write_csv_target(wide_df, here::here(FOLDER, "data", "applicant_wide.csv")),
    format = "file"
  ),

  tar_target(
    file_applicant_skill_ratings,
    write_csv_target(applicant_skill_ratings_df, here::here(FOLDER, "data", "applicant_skill_ratings.csv")),
    format = "file"
  ),

  tar_target(
    file_role_profiles_long,
    write_csv_target(role_profiles_long, here::here(FOLDER, "data", "role_profiles_long.csv")),
    format = "file"
  ),

  tar_target(
    file_mapping,
    write_csv_target(mapping_df, here::here(FOLDER, "data", "mapping.csv")),
    format = "file"
  ),

  # -----------------------
  # SELECTED APPLICANTS
  # -----------------------
  tar_target(
    selected_df,
    {
      tryCatch(load_selected(config$gsheet), error = function(e) tibble::tibble())
    }
  ),

  tar_target(
    selected_file,
    write_csv_target(selected_df, file.path(FOLDER, "data", "selected.csv")),
    format = "file"
  ),

  # -----------------------
  # REPORTS
  # -----------------------

  tarchetypes::tar_render(
    report_by_role,
    here::here("templates", "template_application_report.Rmd"),
    params = list(
      project_id = config$project_ids,
      file_role_profiles_long = file_role_profiles_long,
      file_applicant_project_roles = file_applicant_project_roles,
      file_applicant_wide = file_applicant_wide,
      file_applicant_skill_ratings = file_applicant_skill_ratings,
      by_role = TRUE
    ),
    output_file = here::here(FOLDER, "report-by-role.html")
  ),

  tarchetypes::tar_render(
    report_by_applicant,
    here::here("templates", "template_application_report.Rmd"),
    params = list(
      project_id = config$project_ids,
      file_role_profiles_long = file_role_profiles_long,
      file_applicant_project_roles = file_applicant_project_roles,
      file_applicant_wide = file_applicant_wide,
      file_applicant_skill_ratings = file_applicant_skill_ratings,
      by_role = FALSE
    ),
    output_file = here::here(FOLDER, "report-by-applicant.html")
  )
)
