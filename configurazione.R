# CONFIGURAZIONE - modificare qui le scelte prima di ogni analisi.
# I parametri possono anche essere sovrascritti da riga di comando.

config <- list(
  file_input = "ORL23-24.txt",             # .txt, .tsv, .csv, .xlsx, .xls
  cartella_output = "risultati",
  file_mappatura = "mappatura_servizi.csv", # CSV separato da ;
  foglio_excel = 1,                     # nome o numero del foglio
  codifica_testo = "UTF-8",            # es. "Windows-1252" se il file non e' UTF-8
  imputa_mesi_mancanti_zero = FALSE,    # FALSE: mesi assenti = NA, non zero
  soglia = list(
    mesi_min_outlier = 8,
    mesi_positivi_min_outlier = 4,
    k_mad = 3.5,                     # deviazioni robuste (MAD)
    k_iqr = 1.5,                     # alternativa a MAD
    moltiplicatore_mediana_positiva = 2.5,
    quantita_min_picco = 5,
    quota_concentrazione = 0.65,     # >65% del consumo annuo in un mese
    quantita_min_concentrazione = 20,
    mesi_min_concentrazione = 6,
    mesi_min_confronto_annuo = 6,    # solo mesi comparabili anno su anno
    variazione_annua = 0.50,        # + o - 50%
    differenza_quantita_annua = 10,
    quantita_min_confronto_annuo = 24,
    variazione_costo_unitario = 0.50,# +/-50% rispetto alla mediana
    mesi_min_costo_unitario = 4
  )
)
