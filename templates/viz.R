skill_plot <- function(ratings_role, rating_mapping) {
  p <- ggplot(ratings_role, aes(y = fct_reorder(skill, -pos), color = question, group = question, x = rating_num)) +
    geom_segment(aes(
      y = fct_reorder(skill, -pos),
      yend = fct_reorder(skill, -pos),
      x = 1,
      xend = rating_num
    )) +
    geom_point(size = 3) +
    scale_color_correlaid_d()+
    theme(
      panel.grid.minor.y = element_blank(),
      panel.grid.major.y = element_blank(), 
      legend.position = "bottom"
    ) +
    scale_x_continuous(
      "level",
      limits = c(min(rating_mapping$rating_num), max(rating_mapping$rating_num)),
      breaks = seq(min(rating_mapping$rating_num), max(rating_mapping$rating_num), 1),
      labels = rating_mapping$rating
    ) +
    labs(y = NULL, color = "")
  return(p)
}

load_rating_mapping <- function() {
  tibble::tribble(~rating, ~rating_num, 
                  "beginner", 1,
                  "user", 2,
                  "advanced", 3,
                  "expert", 4)
}