# RStudio specific stuff
# https://twitter.com/JLS_DataScience/status/1587904642670804993?s=20&t=tTPjcXTZW61NZS7fuYDDhQ
on_rstudio <- function(){
  if(commandArgs()[[1L]] == "RStudio") return(TRUE)
  FALSE
}

# if(on_rstudio() & interactive() & )



# Maybe should try this sometime:
#https://stackoverflow.com/questions/6313079/quit-and-restart-a-clean-r-session-from-within-r

# My custom prompt

if (requireNamespace("prompt", quietly = TRUE)) {
  my_prompt <- function(...) paste0("[", prompt :: git_branch(),"]", " > ")
  prompt::set_prompt(my_prompt)


  ## This get's the prompt to show up immediately:
  setHook("rstudio.sessionInit", function(newSession) {
    rstudioapi::sendToConsole("cat(\"\f\")", execute = TRUE)
  }, action = "append")

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

# Clears console and stops startup messages.
# cat("\f")
# cat(" ")

# .First <- function(){
#   if (requireNamespace("prompt", quietly = TRUE)) {
#     my_prompt <- function(...) paste0("[", prompt :: git_branch(),"]", " > ")
#     prompt::set_prompt(my_prompt)
#     rm(my_prompt)
#   }
# }

# .First <- function(){
#   rstudioapi::sendToConsole("Sys.Date()", execute = TRUE)
# }
