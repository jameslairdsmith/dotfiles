#' Restart RStudio
#' @interactive
#' @shortcut Ctrl+Alt+Shift+R
rstudioapi::restartSession

#' Run devtools::load_all()
#' @interactive
#' @shortcut Ctrl+Alt+Shift+L
devtools::load_all

#' Run devtools::test()
#' @shortcut Ctrl+Alt+Shift+T
function() rstudioapi::executeCommand("testPackage")

#' Run devtools::document()
#' @shortcut Ctrl+Alt+Shift+D
function() rstudioapi::executeCommand("roxygenizePackage")

#' Run devtools::document()
#' @shortcut Ctrl+Alt+Shift+P
function() rstudioapi::executeCommand("showCommandPalette")
