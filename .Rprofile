
# RStudio specific stuff
# https://twitter.com/JLS_DataScience/status/1587904642670804993?s=20&t=tTPjcXTZW61NZS7fuYDDhQ
if(commandArgs()[[1L]] == "RStudio"){
  
}

# My custom prompt

if (requireNamespace("prompt", quietly = TRUE)) {
  my_prompt <- function(...) paste0("[", prompt :: git_branch(),"]", " > ")
  prompt::set_prompt(my_prompt)
  rm(my_prompt)
}

# Package dev

options(
  usethis.full_name = "James Laird-Smith",
  #usethis.protocol  = "ssh",
  usethis.description = list(
    "Authors@R" = utils::person(
        "James", "Laird-Smith",
        email = "jameslairdsmith@gmail.com",
        role = c("aut", "cre"),
        comment = c(ORCID = "0000-0003-1175-4046")
    ),
    Version = "0.0.0.9000"
  ),
  #usethis.destdir = "~/the/place/where/I/keep/my/R/projects",
  usethis.overwrite = TRUE
)
