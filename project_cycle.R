library(kbtbr)
library(readr)
library(stringr)
library(dplyr)
library(here)
library(tidyr)
library(janitor)
# for reports 
library(rmarkdown)
library(forcats)
library(ggplot2)
library(correltools)
library(patchwork)

source("utils.R") # custom functions
# please refer to the readme for what the project id is
# this value should be used as a label within the kobo form - for both questions
PROJECTCYCLE_PREFIX <- "2023-10" # EDIT HERE

# kobo instance
kobo <- kbtbr::Kobo$new("kobo.correlaid.org")
all_surveys <- kobo$get_surveys()

# get survey id
survey_id <- all_surveys %>% 
  filter(name == "Applications for CorrelAid Projects") %>% 
  pull(uid)


applications <- kobo$get_submissions(survey_id)


# Kobotoolbox handles data very "wide format-y", so we have to do quite a bit of data wrangling
# this is code from the clean_kobo function in projectutils: https://github.com/CorrelAid/projectutils/blob/cd118871ae5d50c5116fd86935aa11e95a4edf25/R/applications.R#L29 
# it is copied here to allow for easier modifications to the code 

# rename 
applications <- applications %>% dplyr::rename(applicant_id = `_id`, 
                                               motivation_why_involved = motivation_why)

# if the gender self identification variable does not exist, then create it but put NA
if (!"gender_self_identification" %in% colnames(applications)) {
  applications$gender_self_identification <- NA
}

# people can apply to multiple projects at once, data is not stored in separate rows by KoboToolbox
# --> pull "applied to" information into separate rows and data frame
project_ids_df <- applications %>% 
  dplyr::select(applicant_id, project_id) %>% 
  dplyr::mutate(applied_to = project_id) %>% 
  tidyr::separate_rows(project_id, sep = " ") %>% 
  dplyr::mutate(project_id = unify_project_id_formats(project_id)) %>% 
  dplyr::distinct()

# project role: each project has its own column --> make into long data frame
project_roles_df <- applications %>% 
  dplyr::select(applicant_id, dplyr::starts_with("project_role")) %>% 
  tidyr::pivot_longer(dplyr::starts_with("project_role"), names_to = "project_id_unclean", values_to = "project_role") %>%
  dplyr::mutate(project_id = project_id_unclean %>% 
                  extract_ids_from_kobo_columnnames()) %>%
  dplyr::filter(project_role != "DNA") %>% 
  dplyr::distinct() %>% 
  dplyr::select(-project_id_unclean)

# personal informaton and skills
# select variables and rename columns 
personal_info_df <- applications %>% 
  dplyr::select(
    applicant_id,
    dplyr::starts_with("gender"),
    first_name,
    last_name,
    email = email_address,
    german_skills,
    dplyr::starts_with("rating"),
    dplyr::starts_with("motivation"),
    consent_privacy_policy,
    dplyr::starts_with("past_")
  ) %>% 
  dplyr::distinct() %>%
  janitor::clean_names() %>% 
  dplyr::rename_with(
    ~ stringr::str_replace_all(.x,
                               "rating_technologies_tools", "skills"),
    dplyr::starts_with("rating_technologies_tools")
  ) %>%
  dplyr::rename_with( ~ stringr::str_replace_all(.x, "rating_",
                                                 ""),
                      dplyr::starts_with("rating"))

# gender 
personal_info_df <-
  personal_info_df %>% dplyr::mutate(gender = dplyr::if_else(gender ==
                                                               "self_identification", NA_character_, gender))
personal_info_df$gender <- dplyr::coalesce(personal_info_df$gender,
                                           personal_info_df$gender_self_identification)

# join the data frames
cleaned_df <- project_ids_df %>% 
  dplyr::left_join(project_roles_df, by = c("applicant_id", "project_id")) %>% 
  dplyr::left_join(personal_info_df, by = "applicant_id")

cleaned_df$project_id %>% table()

# filter for projectcycle
applications_proj_cycle <- cleaned_df %>% 
  filter(str_starts(project_id, PROJECTCYCLE_PREFIX))

## how many people applied
applications_proj_cycle$applicant_id %>% unique() %>% length()
# number of applications for each project
applications_proj_cycle$project_id %>% table()



# FOR EACH PROJECT - CREATE REPORT AND SAVE DATASETS
project_ids <- unique(applications_proj_cycle$project_id)

for (PROJECT_ID in project_ids) {
  PROJECT_FOLDER <- here::here("projects/", PROJECT_ID)
  # create folder for project
  if (!dir.exists(PROJECT_FOLDER)) {
    dir.create(PROJECT_FOLDER)
  }
  
  # now finally filter for our project!
  appl_proj <- applications_proj_cycle %>% dplyr::filter(project_id == .env$PROJECT_ID)
  
  appl_proj <- appl_proj %>%
    dplyr::select(
      applicant_id,
      gender,
      email,
      dplyr::ends_with("name"),
      dplyr::starts_with("project"),
      applied_to,
      dplyr::starts_with("past"),
      dplyr::starts_with("skills"),
      dplyr::starts_with("techniques"),
      dplyr::starts_with("topics"),
      dplyr::everything()
    )
  
  # anonmyize and save
  appl_anon <- appl_proj %>% 
    select(-email, -first_name, -last_name)
  
  anon_path <- here::here(PROJECT_FOLDER, "applications_anon.csv")
  appl_anon %>% readr::write_csv(anon_path)
  
  # mapping from email / name to applicant_id
  mapping <- appl_proj %>% 
    select(applicant_id, email, first_name, last_name)
  mapping_path <- here::here(PROJECT_FOLDER,  paste(PROJECT_ID, "mapping.csv", sep = "_"))
  mapping %>% readr::write_csv(mapping_path)
  # google sheets upload 
  gs_main_table <- appl_proj %>% 
    dplyr::select(project_id, applicant_id, gender, applied_as = project_role, past_applications) %>% 
    dplyr::arrange(gender, applicant_id)
  gs_main_table_path <- here::here(PROJECT_FOLDER, "google_sheets_main_table.csv")
  gs_main_table %>% readr::write_csv(gs_main_table_path)
  
  
  # knit report 
  rmarkdown::render(here::here("templates/template_applications_report.Rmd"),
                    output_dir = PROJECT_FOLDER, output_file = paste(PROJECT_ID, "applications.html", sep = "_"),
                    params = list(project_id = PROJECT_ID, anon_path = anon_path))
}
