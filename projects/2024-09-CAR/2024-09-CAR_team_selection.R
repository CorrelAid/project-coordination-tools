library(kbtbr)
library(readr)
library(stringr)
library(dplyr)
library(tidyr)
library(janitor)
source("utils.R") # custom functions
# please refer to the readme for what the project id is
# this value should be used as a label within the kobo form - for both questions
PROJECT_ID <- "2024-09-CAR" # REPLACE THIS EXAMPLE VALUE 
PROJECT_FOLDER <- here::here("projects/", PROJECT_ID)
# create folder for project
if (!dir.exists(PROJECT_FOLDER)) {
  dir.create(PROJECT_FOLDER)
}

# kobo instance
kobo <- kbtbr::Kobo$new("kobo.correlaid.org")
all_surveys <- kobo$get_surveys()

# get survey id
survey_id <- all_surveys %>% 
  filter(name == "CorrelAid Projekt - Caritas Fortbildungsakademie") %>% 
  pull(uid)

applications <- kobo$get_submissions(survey_id)

# Kobotoolbox handles data very "wide format-y", so we have to do quite a bit of data wrangling
# this is code from the clean_kobo function in projectutils: https://github.com/CorrelAid/projectutils/blob/cd118871ae5d50c5116fd86935aa11e95a4edf25/R/applications.R#L29 
# it is copied here to allow for easier modifications to the code 

# rename 
applications <- applications %>% 
  dplyr::rename(applicant_id = `_id`, motivation_why_involved = motivation_why) %>% 
  dplyr::mutate(project_id = PROJECT_ID)
  

# if the gender self identification variable does not exist, then create it but put NA
if (!"gender_self_identification" %in% colnames(applications)) {
  applications$gender_self_identification <- NA
}

# project role
project_roles_df <- applications %>% 
  dplyr::select(project_role = project_role,
                applicant_id)
  
# personal informaton and skills
# select variables and rename columns 
personal_info_df <- applications %>% 
  dplyr::select(
    applicant_id,
    dplyr::starts_with("gender"),
    first_name,
    last_name,
    email = email_address,
    dplyr::starts_with("rating"),
    dplyr::starts_with("motivation"),
    consent_privacy_policy,
    dplyr::starts_with("past_")) %>% 
  dplyr::distinct() %>%
  janitor::clean_names() %>% 
  dplyr::rename_with(
    ~ stringr::str_replace_all(.x,
                               "rating_technologies_tools", "skills"),
    dplyr::starts_with("rating_technologies_tools")
  ) %>%
  dplyr::rename_with( ~ stringr::str_replace_all(.x, "rating_",
                                                 ""),
                      dplyr::starts_with("rating")) %>% 
  dplyr::rename(techniques_geodata_processing = techniques_audio_data_processing_001) # question was duplicated and not properly renamed in kobo


# gender 
personal_info_df <-
  personal_info_df %>% dplyr::mutate(gender = dplyr::if_else(gender ==
                                                               "self_identification", NA_character_, gender))
personal_info_df$gender <- dplyr::coalesce(personal_info_df$gender,
                                           personal_info_df$gender_self_identification)

# join the data frames
cleaned_df <- project_roles_df %>% 
  dplyr::left_join(personal_info_df, by = "applicant_id") %>% 
  dplyr::mutate(project_id = PROJECT_ID)

if (nrow(cleaned_df) == 0) {
  usethis::ui_warn(glue::glue("No applicants present after filtering for {project_id}. Did you specify the PROJECT_ID in the correct format?"))
}

cleaned_df <- cleaned_df %>%
  dplyr::select(
    applicant_id,
    gender,
    email,
    dplyr::ends_with("name"),
    dplyr::starts_with("project"),
    dplyr::starts_with("past"),
    dplyr::starts_with("skills"),
    dplyr::starts_with("techniques"),
    dplyr::starts_with("topics"),
    dplyr::everything()
  ) %>% 
  mutate(applied_to = PROJECT_ID) %>% 
  arrange(gender, applicant_id) # sort by gender and id

# anonmyize and save
appl_anon <- cleaned_df %>% 
  select(-email, -first_name, -last_name)

anon_path <- here::here(PROJECT_FOLDER, "applications_anon.csv")
appl_anon %>% readr::write_csv(anon_path)

# mapping from email / name to applicant_id
mapping <- cleaned_df %>% 
  select(applicant_id, email, first_name, last_name)
mapping_path <- here::here(PROJECT_FOLDER, "mapping.csv")
mapping %>% readr::write_csv(mapping_path)

# google sheets upload 
gs_main_table <- cleaned_df %>% 
  dplyr::select(project_id, applicant_id, gender, applied_as = project_role, past_applications)
gs_main_table_path <- here::here(PROJECT_FOLDER, "google_sheets_main_table.csv")
gs_main_table %>% readr::write_csv(gs_main_table_path)


# knit report 
rmarkdown::render(here::here("templates/template_applications_report.Rmd"),
                  output_dir = PROJECT_FOLDER,
                  output_file = paste0(PROJECT_ID, "_applications.html"),
                  params = list(project_id = PROJECT_ID, anon_path = anon_path))

