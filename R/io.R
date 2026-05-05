

load_selected <- function(sheet_url, sheet_name = "mapping") {
  mapping_sheet <- googlesheets4::read_sheet(sheet_url, sheet = sheet_name)
  
  selected_people <- mapping_sheet %>% 
    filter(role != "")
  
  return(selected_people)
}

write_csv_target <- function(df, path) {
  readr::write_csv(df, path)
  path
}