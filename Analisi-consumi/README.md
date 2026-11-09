# Analisi riutilizzabile di consumi per servizio e prodotto (R)

## Obiettivo

Analizzare qualunque estrazione con colonne equivalenti a:

`Servizio`, `Descrizione servizio`, `Prodotto`, `Descrizione prodotto`, `Anno`, `Mese`, `Quantita consumata`, `Valore alimentazione`.

Il numero di righe, gli anni, i codici prodotto, le descrizioni, i valori e i centri di costo NON sono fissati nello script. Sono supportati `txt`/`tsv` delimitati da tabulazioni, `csv` delimitati da `;` o `,`, `xls`/`xlsx`. Le righe iniziali di titolo (come "Titolo del report") vengono saltate automaticamente se l'intestazione e' nelle prime 80 righe.

## Avvio rapido

1. Installare **R >= 4.1** e i pacchetti (solo la prima volta):

   ```r
   install.packages(c("dplyr", "tidyr", "readr", "readxl", "writexl", "ggplot2"))
   ```

2. Modificare `configurazione.R` (percorso di input e output) e `mappatura_servizi.csv`.
3. Da RStudio, impostare come directory di lavoro la cartella degli script e avviare:

   ```r
   source("analisi_consumi.R")
   ```

   Oppure da un terminale (il codice R assume percorsi relativi alla directory corrente):

   ```bash
   Rscript analisi_consumi.R "ORL23-24.txt" "risultati" "mappatura_servizi.csv"
   ```

## Adattamento alle nuove estrazioni

- Modificare solo il percorso del file in `configurazione.R` o il primo argomento da terminale.
- Il file `mappatura_servizi.csv` collega ciascun codice `servizio` a un `ambito`. Le due righe incluse sono **solo un esempio basato sull'estrazione ORL**: verificare che C372 corrisponda effettivamente al perimetro "Ricoveri" nei dati dell'ente. Se i codici cambiano, modificare la mappatura, non il codice R.
- Un codice non presente nella mappatura resta visibile come **"Da classificare"**, non viene assegnato a caso.
- In caso di encoding non UTF-8, cambiare `codifica_testo` (es. `Windows-1252`).
- Se un file Excel ha piu' fogli, modificare `foglio_excel`.
- Modificare le soglie statistiche nella lista `config$soglia`, senza cambiare le funzioni.

## Logica delle medie

L'unita' di analisi e' **servizio + codice prodotto + mese**. Codici e descrizioni sono trattati come testo; le descrizioni non sono usate come chiave, perche' possono variare. Se esistono piu' righe per lo stesso servizio/prodotto/mese, vengono sommate.

- `media_mensile = quantita_totale / mesi_per_media`: include i mesi esplicitamente a consumo **zero**.
- `media_mesi_con_consumo`: media delle quantita' nei soli mesi **positivi** (utile per articoli occasionali, non sostituisce la media generale).
- I mesi del calendario privi di righe per quel servizio/prodotto vengono creati **solo tra il primo e l'ultimo mese in cui il prodotto compare**, contrassegnati `mese_assente = TRUE`, e lasciati `NA` per impostazione predefinita. Non vengono confusi con consumo zero.
- Per trattare i mesi mancanti come zero, impostare `imputa_mesi_mancanti_zero = TRUE`, scelta **da usare solo se l'assenza della riga equivale effettivamente a consumo zero**. `mesi_rilevati` e `mesi_per_media` permettono di verificare il denominatore.
- I prodotti mai comparsi in un anno non sono considerati automaticamente 'consumo zero' in quell'anno.

## Quantita' e valore economico

- I costi con `quantita = 0` e `valore != 0` restano inclusi nel **valore economico complessivo** ma non generano quantita' fisiche.
- `VOCE_SOLO_ECONOMICA`: codice prodotto senza consumi quantitativi positivi nell'intera estrazione. **Non prova da solo che si tratti di un ribaltamento di controllo di gestione**: il codice va classificato con l'ufficio competente.
- `RETTIFICA_SENZA_QUANTITA`: riga a valore senza quantita' per un prodotto che ha anche consumi quantitativi positivi in altri mesi.
- `QUANTITA_NON_VALORIZZATA` e `QUANTITA_NEGATIVA` vengono evidenziati per verifica, senza correggere i dati automaticamente.
- Il dato economico comprende eventuali rettifiche positive e negative. Si producono separatamente `valore_con_quantita` e `valore_senza_quantita`.

## Outlier e altre segnalazioni

- **Outlier mensili**: confronto con il comportamento storico dello stesso `servizio + prodotto`, con soglia MAD (robusta), IQR in alternativa, oppure mediana dei mesi con consumo se entrambe sono zero. Servono almeno 8 mesi osservati e 4 mesi con quantita' positive (parametri modificabili). Le soglie sono prudenziali ma non sono una validazione clinica.
- **Consumi concentrati**: quota di quantita' annua in un singolo mese oltre il 65%, con ulteriori minimi di volume/mesi.
- **Variazioni annue**: confronto tra anni consecutivi solo sui mesi presenti in entrambi gli anni, con minimo 6 mesi comparabili. Esempio: gennaio-settembre 2023 contro gennaio-settembre 2024, non intero 2023 contro 9 mesi del 2024.
- **Costi unitari anomali**: variazioni del rapporto `valore/quantita` rispetto alla mediana storica del prodotto; la segnalazione non equivale a una variazione di prezzo di acquisto, perche' il valore puo' contenere rettifiche.

Le soglie sono parametri iniziali, da tarare con farmacia, economato e controllo di gestione, e possibilmente confrontando ricoveri/prestazioni per ottenere indicatori per attivita' clinica.

**Importante:** i totali delle quantita' di prodotti diversi non vengono sommati nei report per ambito, perche' le unita' di misura possono essere eterogenee (pezzi, confezioni, ml, ecc.).

## Output

Nella cartella `risultati`:

- `analisi_consumi.xlsx`: quadratura dei totali con l'input, prospetti di sintesi, medie per anno e intero periodo, outlier, variazioni, concentrazioni, anomalie economiche, costi senza quantita', voci solo economiche, mesi assenti, codici non classificati e dati importati.
- `outlier_mensili.csv`, `variazioni_annue.csv` per utilizzi successivi.
- `valore_mensile_ambiti.png`, `quantita_top_prodotti.png` per visualizzazione.

## Controlli e limitazioni

- Le colonne obbligatorie e l'anno/mese devono essere validi; nessuna riga invalida e' scartata silenziosamente: lo script si ferma segnalando le righe da correggere.
- Le unita' di misura NON sono in input: il sistema puo' confrontare la quantita' dello stesso codice, ma non affermare che codici diversi misurino la stessa unita'.
- La mediana e gli outlier sono riferiti all'intero periodo contenuto nel file; in presenza di forti cambiamenti strutturali dell'attivita', valutare analisi per segmenti o normalizzazione per numero di procedure.
- I codici possono cambiare nel tempo pur rappresentando lo stesso materiale: senza una tabella di equivalenze, vengono gestiti come prodotti distinti.
- La classificazione per ambito dipende dalla mappatura validata dall'utente.
