#' Restart RStudio
#' @interactive
#' @shortcut Ctrl+Alt+Shift+R
rstudioapi::restartSession

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

#' Run devtools::document()
#' @shortcut Ctrl+Alt+Shift+S
styler:::style_active_file

#' Go to definition
#' @shortcut Ctrl+.
function() rstudioapi::executeCommand("goToDefinition")
