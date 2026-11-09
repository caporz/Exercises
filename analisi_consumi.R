# PUNTO DI AVVIO
# Da terminale:
#   Rscript analisi_consumi.R "ORL23-24.txt" "risultati" "mappatura_servizi.csv"
# Da RStudio: aprire questa cartella come directory di lavoro e fare Source.

argomenti <- commandArgs(trailingOnly = TRUE)
cmd_intero <- commandArgs(trailingOnly = FALSE)
arg_file <- grep("^--file=", cmd_intero, value = TRUE)
cartella_script <- if (length(arg_file)) {
  dirname(normalizePath(sub("^--file=", "", arg_file[[1]]), mustWork = FALSE))
} else {
  getwd()
}
source(file.path(cartella_script, "configurazione.R"), local = TRUE)
source(file.path(cartella_script, "funzioni_consumi.R"), local = TRUE)

if (length(argomenti) >= 1) config$file_input <- argomenti[[1]]
if (length(argomenti) >= 2) config$cartella_output <- argomenti[[2]]
if (length(argomenti) >= 3) config$file_mappatura <- argomenti[[3]]

risultati <- analizza_consumi(config)
