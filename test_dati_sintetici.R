# TEST MANUALE (opzionale) con dataset sintetico: usa le funzioni R senza file esterni.
# Eseguire da RStudio dopo aver impostato questa cartella come directory corrente.
source("configurazione.R")
source("funzioni_consumi.R")
controlla_pacchetti()

mesi <- seq.Date(as.Date("2024-01-01"), as.Date("2024-12-01"), by = "month")
x <- data.frame(
  riga_importata = seq_along(mesi), servizio = "TEST", descrizione_servizio = "Servizio test",
  prodotto = "A1", descrizione_prodotto = "Prodotto test",
  anno = as.integer(format(mesi, "%Y")), mese = as.integer(format(mesi, "%m")),
  quantita = c(rep(10, 10), 80, 10), valore = c(rep(20, 10), 160, 20),
  data = mesi
)
# Inseriamo un mese mancante: deve risultare NA, non zero.
x <- x[x$mese != 7, ]
p <- prepara_dati(x, data.frame(servizio = "TEST", ambito = "Ambulatoriale"))
m <- crea_mensile(p, config)
s <- riassumi_consumo(m)
stopifnot(nrow(m) == 12, sum(m$mese_assente) == 1,
          s$mesi_rilevati == 11, s$mesi_per_media == 11,
          is.na(m$quantita[m$mese == 7]),
          abs(s$quantita_totale - sum(x$quantita)) < 1e-8)
stopifnot(nrow(calcola_outlier(m, config)) >= 1)

# Una voce esclusivamente economica non crea consumo fisico.
y <- x[1, ]
y$prodotto <- "G1"
y$quantita <- 0
y$valore <- 300
y$descrizione_prodotto <- "Riparto costi da verificare"
z <- prepara_dati(rbind(x, y), data.frame(servizio = "TEST", ambito = "Ambulatoriale"))
stopifnot(any(z$tipo_registrazione == "VOCE_SOLO_ECONOMICA"))
message("Test sintetici superati.")
