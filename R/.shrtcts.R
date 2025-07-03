#' Restart RStudio
#' @shortcut Ctrl+Alt+Shift+R
function() rstudioapi::executeCommand("restartR")
## Note: rstudioapi::restartSession does not remove objects in the Global
## environment.
## See: https://github.com/rstudio/rstudioapi/issues/95

#' Run devtools::load_all()
#' @shortcut Ctrl+Alt+Shift+L
function() rstudioapi::executeCommand("devtoolsLoadAll")

#' Run devtools::test()
#' @shortcut Ctrl+Alt+Shift+T
function() rstudioapi::executeCommand("testPackage")

#' Run devtools::document()
#' @shortcut Ctrl+Alt+Shift+D
function() rstudioapi::executeCommand("roxygenizePackage")

#' Run devtools::document()
#' @shortcut Ctrl+Alt+Shift+P
function() rstudioapi::executeCommand("showCommandPalette")

#' Style selection
#' @shortcut Ctrl+Alt+Shift+S
function() rstudioapi::executeCommand("reformatCode")

#' Go to definition
#' @shortcut Ctrl+.
function() rstudioapi::executeCommand("goToDefinition")

#' Wrap markdown text
#' @shortcut Ctrl+Alt+Shift+W
WrapRmd::wrap_rmd_addin
