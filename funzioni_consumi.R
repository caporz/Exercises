# FUNZIONI RIUTILIZZABILI - estrazioni con 8 colonne di base.
# Richiede: R >= 4.1 e pacchetti dplyr, tidyr, readr, readxl, writexl, ggplot2.

pacchetti_richiesti <- c("dplyr", "tidyr", "readr", "readxl", "writexl", "ggplot2")
controlla_pacchetti <- function() {
  mancanti <- pacchetti_richiesti[!vapply(pacchetti_richiesti, requireNamespace, logical(1), quietly = TRUE)]
  if (length(mancanti)) {
    stop("Installare i pacchetti mancanti: install.packages(c(",
         paste(sprintf('"%s"', mancanti), collapse = ", "), "))", call. = FALSE)
  }
}

pulisci_nome <- function(x) {
  x <- iconv(as.character(x), to = "ASCII//TRANSLIT", sub = "")
  x <- tolower(trimws(x))
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_+|_+$", "", x)
}

colonne_obbligatorie <- c(
  "servizio", "descrizione_servizio", "prodotto", "descrizione_prodotto",
  "anno", "mese", "quantita_consumata", "valore_alimentazione"
)

# Identifica la vera intestazione anche se la prima riga e' "Titolo del report".
trova_header_testo <- function(percorso, codifica, estensione) {
  righe <- readLines(percorso, n = 80, warn = FALSE, encoding = codifica)
  separatori <- c("\t", ";", ",", "|")
  if (estensione == "tsv") separatori <- c("\t", separatori)
  for (i in seq_along(righe)) {
    for (sep in separatori) {
      nomi <- pulisci_nome(strsplit(righe[[i]], sep, fixed = TRUE)[[1]])
      if (all(colonne_obbligatorie %in% nomi)) {
        return(list(skip = i - 1L, delim = sep))
      }
    }
  }
  stop("Intestazione non riconosciuta nelle prime 80 righe. Sono richieste: ",
       paste(colonne_obbligatorie, collapse = ", "), call. = FALSE)
}

# Accetta formato italiano 1.234,56 e valori numerici Excel come 1234.56.
# Per testo senza virgola, 1.234 e' interpretato come migliaio (TXT/CSV),
# mentre negli Excel testuali e' interpretato come numero decimale.
numero_da_testo <- function(x, provenienza_excel = FALSE) {
  if (is.numeric(x)) return(as.numeric(x))
  testo <- trimws(as.character(x))
  testo[toupper(testo) %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  testo <- gsub("[[:space:]\u00a0\u20ac]", "", testo, perl = TRUE)
  testo <- gsub("^\\((.+)\\)$", "-\\1", testo)
  con_virgola <- !is.na(testo) & grepl(",", testo, fixed = TRUE)
  testo[con_virgola] <- gsub(".", "", testo[con_virgola], fixed = TRUE)
  testo[con_virgola] <- sub(",", ".", testo[con_virgola], fixed = TRUE)
  if (!provenienza_excel) {
    # Stringhe tipo 1.000 (senza virgola): convenzione italiana = 1000.
    raggruppate <- !is.na(testo) & !con_virgola &
      grepl("^[+-]?[0-9]{1,3}(\\.[0-9]{3})+$", testo)
    testo[raggruppate] <- gsub(".", "", testo[raggruppate], fixed = TRUE)
  }
  suppressWarnings(as.numeric(testo))
}

primo_non_vuoto <- function(x) {
  x <- trimws(as.character(x))
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x)) x[[1]] else NA_character_
}

importa_estrazione <- function(percorso, cfg) {
  if (!file.exists(percorso)) stop("File di input non trovato: ", percorso, call. = FALSE)
  ext <- tolower(tools::file_ext(percorso))
  da_excel <- ext %in% c("xlsx", "xls")
  if (da_excel) {
    anteprima <- readxl::read_excel(
      percorso, sheet = cfg$foglio_excel, n_max = 80,
      col_names = FALSE, col_types = "text", .name_repair = "minimal"
    )
    pos <- which(vapply(seq_len(nrow(anteprima)), function(i) {
      all(colonne_obbligatorie %in% pulisci_nome(unlist(anteprima[i, ], use.names = FALSE)))
    }, logical(1)))
    if (!length(pos)) stop("Intestazione Excel non riconosciuta (prime 80 righe).", call. = FALSE)
    dati <- readxl::read_excel(
      percorso, sheet = cfg$foglio_excel, skip = pos[[1]] - 1L,
      col_types = "text", .name_repair = "minimal"
    )
  } else if (ext %in% c("txt", "tsv", "csv")) {
    hd <- trova_header_testo(percorso, cfg$codifica_testo, ext)
    dati <- readr::read_delim(
      percorso, delim = hd$delim, skip = hd$skip,
      col_types = readr::cols(.default = readr::col_character()),
      locale = readr::locale(encoding = cfg$codifica_testo),
      show_col_types = FALSE, progress = FALSE, name_repair = "minimal"
    )
  } else {
    stop("Formato non supportato: ", ext, ". Utilizzare TXT/TSV/CSV/XLSX/XLS.", call. = FALSE)
  }

  names(dati) <- pulisci_nome(names(dati))
  if (anyDuplicated(names(dati))) stop("Nomi di colonna duplicati dopo la normalizzazione.", call. = FALSE)
  assenti <- setdiff(colonne_obbligatorie, names(dati))
  if (length(assenti)) stop("Colonne obbligatorie assenti: ", paste(assenti, collapse = ", "), call. = FALSE)
  if (!nrow(dati)) stop("Nessuna riga dati nel file di input.", call. = FALSE)

  out <- dati |>
    dplyr::transmute(
      riga_importata = dplyr::row_number(),
      servizio = trimws(as.character(.data$servizio)),
      descrizione_servizio = trimws(as.character(.data$descrizione_servizio)),
      prodotto = trimws(as.character(.data$prodotto)),
      descrizione_prodotto = trimws(as.character(.data$descrizione_prodotto)),
      anno = numero_da_testo(.data$anno, da_excel),
      mese = numero_da_testo(.data$mese, da_excel),
      quantita = numero_da_testo(.data$quantita_consumata, da_excel),
      valore = numero_da_testo(.data$valore_alimentazione, da_excel)
    )
  invalidi <- is.na(out$anno) | is.na(out$mese) | is.na(out$quantita) |
    is.na(out$valore) | is.na(out$servizio) | out$servizio == "" |
    is.na(out$prodotto) | out$prodotto == "" |
    out$anno != floor(out$anno) | out$anno < 1900 | out$anno > 2100 |
    out$mese != floor(out$mese) | out$mese < 1 | out$mese > 12
  invalidi[is.na(invalidi)] <- TRUE
  if (any(invalidi)) {
    stop("Dati mancanti o non interpretabili nelle righe importate: ",
         paste(utils::head(out$riga_importata[invalidi], 12), collapse = ", "),
         ". Nessuna riga viene scartata automaticamente.", call. = FALSE)
  }
  out$anno <- as.integer(out$anno)
  out$mese <- as.integer(out$mese)
  out$data <- as.Date(sprintf("%04d-%02d-01", out$anno, out$mese))
  out
}

leggi_mappatura <- function(percorso) {
  if (!file.exists(percorso)) {
    warning("Mappatura servizi non trovata: tutti i servizi saranno 'Da classificare'.")
    return(data.frame(servizio = character(), ambito = character()))
  }
  m <- readr::read_delim(percorso, delim = ";", col_types = readr::cols(.default = "c"),
                         show_col_types = FALSE, progress = FALSE)
  names(m) <- pulisci_nome(names(m))
  if (!all(c("servizio", "ambito") %in% names(m))) {
    stop("La mappatura deve contenere le colonne 'servizio' e 'ambito'.", call. = FALSE)
  }
  m <- m |>
    dplyr::transmute(servizio = trimws(.data$servizio), ambito = trimws(.data$ambito))
  if (anyDuplicated(m$servizio)) stop("Codici servizio duplicati nella mappatura.", call. = FALSE)
  if (any(is.na(m$servizio) | m$servizio == "" | is.na(m$ambito) | m$ambito == "")) {
    stop("La mappatura contiene codici o ambiti vuoti.", call. = FALSE)
  }
  m
}

prepara_dati <- function(dati, mappa) {
  dati |>
    dplyr::left_join(mappa, by = "servizio") |>
    dplyr::mutate(ambito = dplyr::coalesce(.data$ambito, "Da classificare")) |>
    dplyr::group_by(.data$servizio, .data$prodotto) |>
    dplyr::mutate(prodotto_con_consumi = any(.data$quantita > 0)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      tipo_registrazione = dplyr::case_when(
        .data$quantita < 0 ~ "QUANTITA_NEGATIVA",
        .data$quantita != 0 & .data$valore < 0 ~ "VALORE_NEGATIVO_CON_QUANTITA",
        .data$quantita > 0 & .data$valore == 0 ~ "QUANTITA_NON_VALORIZZATA",
        .data$quantita == 0 & .data$valore != 0 & !.data$prodotto_con_consumi ~ "VOCE_SOLO_ECONOMICA",
        .data$quantita == 0 & .data$valore != 0 & .data$prodotto_con_consumi ~ "RETTIFICA_SENZA_QUANTITA",
        TRUE ~ "REGOLARE"
      ),
      valore_senza_quantita = dplyr::if_else(.data$quantita == 0, .data$valore, 0),
      valore_con_quantita = dplyr::if_else(.data$quantita != 0, .data$valore, 0)
    )
}

catalogo_prodotti <- function(dati) {
  dati |>
    dplyr::arrange(dplyr::desc(.data$data)) |>
    dplyr::group_by(.data$servizio, .data$prodotto) |>
    dplyr::summarise(
      descrizione_prodotto = primo_non_vuoto(.data$descrizione_prodotto),
      descrizione_servizio = primo_non_vuoto(.data$descrizione_servizio),
      n_descrizioni_prod = dplyr::n_distinct(.data$descrizione_prodotto, na.rm = TRUE),
      .groups = "drop"
    )
}

crea_mensile <- function(dati, cfg) {
  catalogo <- catalogo_prodotti(dati)
  base <- dati |>
    dplyr::group_by(.data$servizio, .data$ambito, .data$prodotto, .data$data) |>
    dplyr::summarise(
      quantita = sum(.data$quantita),
      valore = sum(.data$valore),
      valore_senza_quantita = sum(.data$valore_senza_quantita),
      valore_con_quantita = sum(.data$valore_con_quantita),
      n_righe_originali = dplyr::n(),
      .groups = "drop"
    )
  # Inserisce solo i mesi compresi fra prima e ultima riga di quel prodotto/servizio.
  mensile <- base |>
    dplyr::group_by(.data$servizio, .data$ambito, .data$prodotto) |>
    tidyr::complete(data = seq.Date(min(.data$data), max(.data$data), by = "month")) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      mese_assente = is.na(.data$n_righe_originali),
      anno = as.integer(format(.data$data, "%Y")),
      mese = as.integer(format(.data$data, "%m"))
    ) |>
    dplyr::left_join(catalogo, by = c("servizio", "prodotto"))
  if (isTRUE(cfg$imputa_mesi_mancanti_zero)) {
    colonne <- c("quantita", "valore", "valore_senza_quantita", "valore_con_quantita")
    for (col in colonne) mensile[[col]][mensile$mese_assente] <- 0
  }
  mensile |>
    dplyr::arrange(.data$ambito, .data$servizio, .data$prodotto, .data$data)
}

# Media calendariale: include gli zeri realmente presenti nel file;
# per default esclude i mesi completamente assenti (NA non = zero).
riassumi_consumo <- function(mensile, per_anno = TRUE) {
  chiavi <- c("ambito", "servizio", "prodotto", "descrizione_prodotto")
  if (per_anno) chiavi <- c(chiavi, "anno")
  mensile |>
    dplyr::group_by(dplyr::across(dplyr::all_of(chiavi))) |>
    dplyr::summarise(
      dal = min(.data$data), al = max(.data$data),
      mesi_calendario = dplyr::n(),
      mesi_rilevati = sum(!.data$mese_assente),
      mesi_per_media = sum(!is.na(.data$quantita)),
      mesi_con_consumo = sum(.data$quantita > 0, na.rm = TRUE),
      quantita_totale = sum(.data$quantita, na.rm = TRUE),
      media_mensile = if (sum(!is.na(.data$quantita)) > 0)
        sum(.data$quantita, na.rm = TRUE) / sum(!is.na(.data$quantita)) else NA_real_,
      media_mesi_con_consumo = if (sum(.data$quantita > 0, na.rm = TRUE) > 0)
        sum(.data$quantita[.data$quantita > 0], na.rm = TRUE) / sum(.data$quantita > 0, na.rm = TRUE) else NA_real_,
      valore_totale = sum(.data$valore, na.rm = TRUE),
      valore_con_quantita = sum(.data$valore_con_quantita, na.rm = TRUE),
      valore_senza_quantita = sum(.data$valore_senza_quantita, na.rm = TRUE),
      media_valore_mensile = if (sum(!is.na(.data$valore)) > 0)
        sum(.data$valore, na.rm = TRUE) / sum(!is.na(.data$valore)) else NA_real_,
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$ambito, .data$servizio, .data$prodotto)
}

riassumi_ambiti <- function(dati) {
  dati |>
    dplyr::group_by(.data$ambito, .data$anno) |>
    dplyr::summarise(
      mesi_presenti = dplyr::n_distinct(.data$data),
      prodotti_distinti = dplyr::n_distinct(.data$servizio, .data$prodotto),
      valore_totale = sum(.data$valore),
      valore_con_quantita = sum(.data$valore_con_quantita),
      valore_senza_quantita = sum(.data$valore_senza_quantita),
      media_valore_mensile = sum(.data$valore) / dplyr::n_distinct(.data$data),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$ambito, .data$anno)
}

# Outlier robusti: mediana + MAD; se MAD=0 si prova IQR; se anche IQR=0
# si confronta con la mediana dei soli mesi a consumo positivo.
calcola_outlier <- function(mensile, cfg) {
  s <- cfg$soglia
  statistiche <- mensile |>
    dplyr::group_by(.data$servizio, .data$prodotto) |>
    dplyr::summarise(
      mesi_osservati = sum(!is.na(.data$quantita)),
      mesi_positivi = sum(.data$quantita > 0, na.rm = TRUE),
      mediana = stats::median(.data$quantita, na.rm = TRUE),
      mad = stats::mad(.data$quantita, constant = 1.4826, na.rm = TRUE),
      iqr = stats::IQR(.data$quantita, na.rm = TRUE),
      q3 = as.numeric(stats::quantile(.data$quantita, 0.75, na.rm = TRUE)),
      mediana_positiva = if (sum(.data$quantita > 0, na.rm = TRUE) > 0)
        stats::median(.data$quantita[.data$quantita > 0], na.rm = TRUE) else NA_real_,
      .groups = "drop"
    ) |>
    dplyr::mutate(
      metodo = dplyr::case_when(.data$mad > 0 ~ "MAD", .data$iqr > 0 ~ "IQR", TRUE ~ "MEDIANA_POSITIVA"),
      limite_statistico = dplyr::case_when(
        .data$mad > 0 ~ .data$mediana + s$k_mad * .data$mad,
        .data$iqr > 0 ~ .data$q3 + s$k_iqr * .data$iqr,
        TRUE ~ .data$mediana_positiva * 3
      ),
      limite = pmax(.data$limite_statistico,
                    .data$mediana_positiva * s$moltiplicatore_mediana_positiva,
                    s$quantita_min_picco, na.rm = TRUE)
    )
  mensile |>
    dplyr::left_join(statistiche, by = c("servizio", "prodotto")) |>
    dplyr::filter(
      !.data$mese_assente, !is.na(.data$quantita),
      .data$mesi_osservati >= s$mesi_min_outlier,
      .data$mesi_positivi >= s$mesi_positivi_min_outlier,
      .data$quantita > .data$limite,
      .data$quantita > 0
    ) |>
    dplyr::select(dplyr::all_of(c("ambito", "servizio", "prodotto", "descrizione_prodotto", "anno", "mese", "data", "quantita", "valore", "metodo", "mediana", "mediana_positiva", "limite", "mesi_osservati", "mesi_positivi"))) |>
    dplyr::arrange(dplyr::desc(.data$quantita / pmax(.data$limite, 1)))
}

calcola_concentrazioni <- function(mensile, cfg) {
  s <- cfg$soglia
  mensile |>
    dplyr::group_by(.data$ambito, .data$servizio, .data$prodotto,
                    .data$descrizione_prodotto, .data$anno) |>
    dplyr::summarise(
      mesi_osservati = sum(!is.na(.data$quantita)),
      mesi_positivi = sum(.data$quantita > 0, na.rm = TRUE),
      quantita_annua = sum(.data$quantita, na.rm = TRUE),
      massimo_mensile = max(.data$quantita, na.rm = TRUE),
      mese_massimo = .data$mese[which.max(replace(.data$quantita, is.na(.data$quantita), -Inf))],
      .groups = "drop"
    ) |>
    dplyr::mutate(quota_del_massimo = dplyr::if_else(.data$quantita_annua > 0,
                                                   .data$massimo_mensile / .data$quantita_annua, NA_real_)) |>
    dplyr::filter(.data$mesi_osservati >= s$mesi_min_concentrazione,
                  .data$mesi_positivi >= 2,
                  .data$quantita_annua >= s$quantita_min_concentrazione,
                  .data$quota_del_massimo > s$quota_concentrazione) |>
    dplyr::arrange(dplyr::desc(.data$quota_del_massimo))
}

# Confronto annuo su stessi mesi presenti in ENTRAMBI gli anni.
calcola_variazioni_annue <- function(mensile, cfg) {
  s <- cfg$soglia
  osservati <- mensile |>
    dplyr::filter(!.data$mese_assente) |>
    dplyr::select(dplyr::all_of(c("servizio", "prodotto", "anno", "mese", "quantita")))
  anno_precedente <- osservati |>
    dplyr::transmute(servizio = .data$servizio, prodotto = .data$prodotto,
                     anno = .data$anno + 1L, mese = .data$mese,
                     q_precedente = .data$quantita)
  osservati |>
    dplyr::rename(q_corrente = quantita) |>
    dplyr::inner_join(anno_precedente, by = c("servizio", "prodotto", "anno", "mese")) |>
    dplyr::group_by(.data$servizio, .data$prodotto, .data$anno) |>
    dplyr::summarise(
      mesi_confrontabili = dplyr::n(),
      q_precedente = sum(.data$q_precedente),
      q_corrente = sum(.data$q_corrente),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      variazione_perc = dplyr::if_else(.data$q_precedente != 0,
                                     .data$q_corrente / .data$q_precedente - 1, NA_real_),
      differenza_quantita = .data$q_corrente - .data$q_precedente,
      tipo_variazione = dplyr::case_when(
        .data$q_precedente == 0 & .data$q_corrente > 0 ~ "BASE_ZERO",
        .data$q_precedente > 0 & .data$q_corrente == 0 ~ "AZZERAMENTO",
        .data$variazione_perc > 0 ~ "AUMENTO",
        .data$variazione_perc < 0 ~ "RIDUZIONE",
        TRUE ~ "INVARIATO"
      )
    ) |>
    dplyr::filter(
      .data$mesi_confrontabili >= s$mesi_min_confronto_annuo,
      abs(.data$differenza_quantita) >= s$differenza_quantita_annua,
      pmax(abs(.data$q_precedente), abs(.data$q_corrente)) >= s$quantita_min_confronto_annuo,
      (.data$q_precedente == 0 & .data$q_corrente > 0) |
        (!is.na(.data$variazione_perc) & abs(.data$variazione_perc) >= s$variazione_annua)
    ) |>
    dplyr::left_join(
      mensile |>
        dplyr::distinct(.data$servizio, .data$prodotto, .data$ambito, .data$descrizione_prodotto),
      by = c("servizio", "prodotto")
    ) |>
    dplyr::relocate(ambito, .before = servizio) |>
    dplyr::arrange(dplyr::desc(abs(.data$differenza_quantita)))
}

calcola_costi_unitari_anomali <- function(mensile, cfg) {
  s <- cfg$soglia
  buoni <- mensile |>
    dplyr::filter(!.data$mese_assente, .data$quantita > 0, .data$valore > 0) |>
    dplyr::mutate(costo_unitario = .data$valore / .data$quantita)
  base <- buoni |>
    dplyr::group_by(.data$servizio, .data$prodotto) |>
    dplyr::summarise(mesi_utili = dplyr::n(),
                     costo_unitario_mediano = stats::median(.data$costo_unitario), .groups = "drop")
  buoni |>
    dplyr::left_join(base, by = c("servizio", "prodotto")) |>
    dplyr::mutate(rapporto_su_mediana = .data$costo_unitario / .data$costo_unitario_mediano) |>
    dplyr::filter(.data$mesi_utili >= s$mesi_min_costo_unitario,
                  .data$costo_unitario_mediano > 0,
                  .data$rapporto_su_mediana > 1 + s$variazione_costo_unitario |
                    .data$rapporto_su_mediana < 1 / (1 + s$variazione_costo_unitario)) |>
    dplyr::select(dplyr::all_of(c("ambito", "servizio", "prodotto", "descrizione_prodotto", "anno", "mese", "quantita", "valore", "costo_unitario", "costo_unitario_mediano", "rapporto_su_mediana", "mesi_utili"))) |>
    dplyr::arrange(dplyr::desc(abs(log(.data$rapporto_su_mediana))))
}

# Controllo di quadratura: la somma tecnica delle quantita' serve SOLO
# a verificare che nessuna riga sia persa (NON e' un KPI clinico).
verifica_integrita <- function(dati, mensile) {
  nomi <- c("Valore complessivo", "Valore con quantita'", "Valore senza quantita'", "Quantita' tecniche (solo quadratura)")
  origine <- c(sum(dati$valore), sum(dati$valore_con_quantita),
               sum(dati$valore_senza_quantita), sum(dati$quantita))
  aggregato <- c(sum(mensile$valore, na.rm = TRUE),
                 sum(mensile$valore_con_quantita, na.rm = TRUE),
                 sum(mensile$valore_senza_quantita, na.rm = TRUE),
                 sum(mensile$quantita, na.rm = TRUE))
  tabella <- data.frame(indicatore = nomi, estrazione = origine,
                        aggregazione_mensile = aggregato, differenza = aggregato - origine)
  if (any(abs(tabella$differenza) > 0.0001)) {
    stop("La quadratura dati/mensile non torna. Interrompo l'analisi.", call. = FALSE)
  }
  tabella
}

crea_report <- function(dati, mensile, cfg) {
  righe_economiche <- dati |>
    dplyr::filter(.data$quantita == 0, .data$valore != 0) |>
    dplyr::select(dplyr::all_of(c("ambito", "servizio", "prodotto", "descrizione_prodotto", "anno", "mese", "valore", "tipo_registrazione")))

  voci_solo_econ <- dati |>
    dplyr::filter(.data$tipo_registrazione == "VOCE_SOLO_ECONOMICA") |>
    dplyr::group_by(.data$ambito, .data$servizio, .data$prodotto) |>
    dplyr::summarise(
      descrizione_prodotto = primo_non_vuoto(.data$descrizione_prodotto),
      mesi_valorizzati = dplyr::n_distinct(.data$data),
      valore_totale = sum(.data$valore), .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(abs(.data$valore_totale)))

  altre_anomalie <- dati |>
    dplyr::filter(.data$tipo_registrazione %in% c("QUANTITA_NEGATIVA", "VALORE_NEGATIVO_CON_QUANTITA", "QUANTITA_NON_VALORIZZATA")) |>
    dplyr::select(dplyr::all_of(c("ambito", "servizio", "prodotto", "descrizione_prodotto", "anno", "mese", "quantita", "valore", "tipo_registrazione")))

  v_descr <- dati |>
    dplyr::group_by(.data$servizio, .data$prodotto) |>
    dplyr::summarise(n_descrizioni = dplyr::n_distinct(.data$descrizione_prodotto),
                     descrizioni = paste(unique(.data$descrizione_prodotto), collapse = " | "),
                     .groups = "drop") |>
    dplyr::filter(.data$n_descrizioni > 1)

  list(
    `Controlli_integrita` = verifica_integrita(dati, mensile),
    `Sintesi_ambito_anno` = riassumi_ambiti(dati),
    `Medie_prodotto_anno` = riassumi_consumo(mensile, per_anno = TRUE),
    `Medie_intero_periodo` = riassumi_consumo(mensile, per_anno = FALSE),
    `Outlier_mensili` = calcola_outlier(mensile, cfg),
    `Variazioni_annue` = calcola_variazioni_annue(mensile, cfg),
    `Consumi_concentrati` = calcola_concentrazioni(mensile, cfg),
    `Costi_unitari_anomali` = calcola_costi_unitari_anomali(mensile, cfg),
    `Costi_senza_quantita` = righe_economiche,
    `Voci_solo_economiche` = voci_solo_econ,
    `Altre_anomalie` = altre_anomalie,
    `Mesi_assenti` = mensile |>
      dplyr::filter(.data$mese_assente) |>
      dplyr::select(dplyr::all_of(c("ambito", "servizio", "prodotto", "descrizione_prodotto", "anno", "mese"))),
    `Servizi_senza_mappatura` = dati |>
      dplyr::filter(.data$ambito == "Da classificare") |>
      dplyr::distinct(.data$servizio, .data$descrizione_servizio),
    `Descrizioni_variabili` = v_descr,
    `Dati_mensili` = mensile,
    `Dati_importati` = dati |>
      dplyr::select(-"prodotto_con_consumi")
  )
}

crea_grafici <- function(dati, mensile, cartella) {
  economici <- dati |>
    dplyr::group_by(.data$ambito, .data$data) |>
    dplyr::summarise(valore = sum(.data$valore), .groups = "drop")
  figura <- ggplot2::ggplot(economici, ggplot2::aes(x = .data$data, y = .data$valore)) +
    ggplot2::geom_line(linewidth = 0.8, color = "#187C85") +
    ggplot2::geom_point(size = 1.4, color = "#187C85") +
    ggplot2::facet_wrap(~ambito, scales = "free_y", ncol = 1) +
    ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%m/%Y") +
    ggplot2::labs(title = "Valore mensile per ambito", x = NULL,
                  y = "Valore economico (EUR)", caption = "Inclusi importi senza quantita' e rettifiche") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
  ggplot2::ggsave(file.path(cartella, "valore_mensile_ambiti.png"), figura,
                  width = 11, height = 6.5, dpi = 160)

  # Non sommare le quantita' di prodotti differenti: unita' di misura non omogenee.
  top <- dati |>
    dplyr::filter(.data$quantita > 0) |>
    dplyr::group_by(.data$servizio, .data$prodotto) |>
    dplyr::summarise(valore = sum(abs(.data$valore_con_quantita)), .groups = "drop") |>
    dplyr::slice_max(.data$valore, n = 9, with_ties = FALSE)
  serie <- mensile |>
    dplyr::semi_join(top, by = c("servizio", "prodotto")) |>
    dplyr::mutate(etichetta = paste0(.data$servizio, " | ", .data$prodotto))
  if (nrow(serie)) {
    g <- ggplot2::ggplot(serie, ggplot2::aes(x = .data$data, y = .data$quantita)) +
      ggplot2::geom_line(color = "#187C85", linewidth = 0.65, na.rm = TRUE) +
      ggplot2::geom_point(color = "#187C85", size = 1, na.rm = TRUE) +
      ggplot2::facet_wrap(~etichetta, scales = "free_y", ncol = 3) +
      ggplot2::labs(title = "Consumo mensile dei 9 prodotti di maggiore valore",
                    x = NULL, y = "Quantita' del singolo prodotto") +
      ggplot2::theme_minimal(base_size = 10) +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    ggplot2::ggsave(file.path(cartella, "quantita_top_prodotti.png"), g,
                    width = 13, height = 9, dpi = 160)
  }
}

analizza_consumi <- function(cfg) {
  controlla_pacchetti()
  if (!is.logical(cfg$imputa_mesi_mancanti_zero) || length(cfg$imputa_mesi_mancanti_zero) != 1) {
    stop("'imputa_mesi_mancanti_zero' deve essere TRUE o FALSE.", call. = FALSE)
  }
  raw <- importa_estrazione(cfg$file_input, cfg)
  mappa <- leggi_mappatura(cfg$file_mappatura)
  dati <- prepara_dati(raw, mappa)
  mensile <- crea_mensile(dati, cfg)
  report <- crea_report(dati, mensile, cfg)

  dir.create(cfg$cartella_output, recursive = TRUE, showWarnings = FALSE)
  file_excel <- file.path(cfg$cartella_output, "analisi_consumi.xlsx")
  writexl::write_xlsx(report, file_excel)
  readr::write_csv(report$Outlier_mensili,
                   file.path(cfg$cartella_output, "outlier_mensili.csv"), na = "")
  readr::write_csv(report$Variazioni_annue,
                   file.path(cfg$cartella_output, "variazioni_annue.csv"), na = "")
  crea_grafici(dati, mensile, cfg$cartella_output)

  cat("\nANALISI COMPLETATA\n")
  cat("Righe importate: ", nrow(dati), "\n", sep = "")
  cat("Prodotti distinti (servizio/prodotto): ",
      nrow(dplyr::distinct(dati, .data$servizio, .data$prodotto)), "\n", sep = "")
  cat("Intervallo: ", as.character(min(dati$data)), " / ", as.character(max(dati$data)), "\n", sep = "")
  cat("Valore totale: EUR ", format(round(sum(dati$valore), 2), big.mark = ".", decimal.mark = ","), "\n", sep = "")
  cat("Outlier mensili: ", nrow(report$Outlier_mensili), "\n", sep = "")
  cat("Variazioni annue rilevanti: ", nrow(report$Variazioni_annue), "\n", sep = "")
  cat("Mesi non presenti nell'estrazione: ", nrow(report$Mesi_assenti), "\n", sep = "")
  if (nrow(report$Servizi_senza_mappatura)) {
    warning("Ci sono servizi da classificare: controllare il foglio 'Servizi_senza_mappatura'.")
  }
  cat("Output Excel: ", normalizePath(file_excel), "\n", sep = "")
  invisible(report)
}
