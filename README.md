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
Scripts are written in R so far. Feel free to contribute Python versions. 

1. [Install R and RStudio](https://www.dataquest.io/blog/tutorial-getting-started-with-r-and-rstudio/)
2. In the "console" winndow in RStudio, enter `install.packages("renv")` to install the `renv` package
3. run `renv::restore()` to install the dependencies of this repository. 

## KoboToolbox API token
For the processing of applications, you need the API token from a [CorrelAid KoboToolbox](https://kobo.correlaid.org) account that has access to the form "Applications for CorrelAid Projects". 

1. install the `usethis` R package: `install.packages("usethis")`
2. in the "console" window in RStudio enter `usethis::edit_r_environ()`. This will open the user environment file for R. 
3. Log into your account and open the [security settings](https://kobo.correlaid.org/#/account/security)
4. Copy the API token and paste in the environment file (see step 2):

```
KBTBR_TOKEN="YOUR TOKEN"
```

5. Restart RStudio. 

# Team selection 
**Optional**: if you know that you want to make edits to the scripts, then create a project folder for your project under `projects` with the project ID as the subfolder name. For example: `projects/2022-04-LAU`. You can then copy the `team_selection.R` script to this folder and edit it as you wish. Otherwise, the script in the root will create this folder for you for the outputs.
## Generate HTML report and create datasets
1. Open `team_selection.R` and replace `PROJECT_ID` with your project id in line 10. 
2. Run the script line by line or _source_ it ("Run" respectively "Source" button in RStudio). 
3. This will create a project folder under `projects` with with different csv files and the **HTML report** used for team selection.

- `applications.csv`: applications for the project
- `applications_anon.csv`: anonymized applications, i.e. name and email address removed
- `mapping.csv`: mapping of applicant ID to name and email address to contact people after team selection.  
- `google_sheets_main_table.csv`: heavily anonymized version (only applicant_id, role and gender) to upload to the main table of the google sheets template
