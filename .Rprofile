
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
