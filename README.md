# Purpose
Tools and scripts to (semi-)automate tasks to the coordination of CorrelAid Data4Good projects.

Features: 

- pull applications from KoboToolbox & generate HTML report for anonymized team selection

# Requirements

## Project ID
You need a project id that has been used in KoboToolbox. It **must** have the following format: `YYYY-mm-[three uppercase letters]`. This is critical as data cleaning and downstream activities depend on this.

The project ID has three components:

- Year in which the project started.
- Month in which the project started.
- Three-letter, uppercase identifier for the organization. Usually the first three letters of the organization’s name, unless it has a three-letter acronym (e.g in the case of the European Youth Parliament, we use EYP). If there are two projects starting with the same organization in a given month, we can give a three letter acronym that refers more to the content, e.g. EDA for exploratory data analysis.

The components are arranged as follows: {year}-{month}-{identifier}

## R Packages
Scripts are written in R so far. 

1. [Install R and RStudio](https://www.dataquest.io/blog/tutorial-getting-started-with-r-and-rstudio/)
2. In the "console" winndow in RStudio, enter `install.packages("renv")` to install the `renv` package
3. run `renv::restore()` to install the dependencies of this repository. 

## KoboToolbox API token
For the processing of applications, you need the API token from a [CorrelAid KoboToolbox](https://kobo.correlaid.org) account that has access to the survey/application form you want to process.

Log into your account and open the [security settings](https://kobo.correlaid.org/#/account/security)

# Using the tools

This project uses `targets` for workflow orchestration.

1. Create folder under `projects/`, e.g. using your project ID or YYYY-mm if you want to do team selection for multiple projects
2. Create `.env` file in the folder and fill:

```
KBTBR_TOKEN="KOBO TOKEN HERE"
PROJECT_IDS="2026-12-EXA" # comma separated if multiple project ids
KOBO_SURVEY_ID="KOBO ASSET ID HERE" # asset id of the kobo survey (you can find this in the survey url at kobo.correlaid.org)
GSHEET="Google Sheets URL where you did anonymized team selection" # only needed if you want to do the selected team report as well.
```

3. open `_targets.R` and change `FOLDER` definition in line 20. This will make sure that your `.env` file is loaded
4. run `tar_make()` in the console


Refer to the [targets documentation](https://books.ropensci.org/targets/) if you run into problems. Especially relevant could be the following commands.

- `targets::tar_invalidate(applications_raw)` to rerun loading data from Kobo
- `targets::tar_make(dplyr::starts_with("file"))` to update all the files (e.g. `gs_upload.csv`)
- `targets::tar_make(dplyr::starts_with("report_by"))` to update the reports for team selection
- `targets::tar_make(report_teams)` to update the reports after team selection

