# Purpose
Tools and scripts to (semi-)automate tasks to the coordination of CorrelAid Data4Good projects.

Features: 

- pull applications from KoboToolbox & generate HTML report for anonymized team selection

# Requirements
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

1. Open `team_selection.R` and replace `PROJECT_ID` with your project id in line 10. 
2. Run the script line by line or _source_ it ("Run" respectively "Source" button in RStudio). This will create a project folder under `projects` with with different csv files and the HTML report used for team selection.

- `applications.csv`: applications for the project
- `applications_anon.csv`: anonymized applications, i.e. name and email address removed
- `mapping.csv`: mapping of applicant ID to name and email address to contact people after team selection.  




## Download data 
The script `process_data.R` helps you to automatically download and clean the data from KoboToolbox via the API.
Right now, the script will not work 
# Onboarding

projectutils::c
# quarto 

