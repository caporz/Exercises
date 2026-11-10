# Reusable Consumption Analysis by Service and Product (R)

## Objective

Analyze any data extract containing columns equivalent to:

`Servizio`, `Descrizione servizio`, `Prodotto`, `Descrizione prodotto`, `Anno`, `Mese`, `Quantita consumata`, `Valore alimentazione`.

The number of rows, years, product codes, descriptions, values, and cost centers are **not hardcoded in the script**.

The script supports `txt`/`tsv` files delimited by tabs, `csv` files delimited by `;` or `,`, and `xls`/`xlsx` files. Initial title rows (such as "Report Title") are automatically skipped if the header row is found within the first 80 rows.

## Quick Start

1. Install **R >= 4.1** and the required packages (first-time setup only):

   ```r
   install.packages(c("dplyr", "tidyr", "readr", "readxl", "writexl", "ggplot2"))
   ```

2. Edit `configurazione.R` (input and output paths) and `mappatura_servizi.csv`.
3. In RStudio, set the scripts folder as the working directory and run:

   ```r
   source("analisi_consumi.R")
   ```

   Alternatively, run the script from a terminal (R code assumes paths are relative to the current working directory):

   ```bash
   Rscript analisi_consumi.R "ORL23-24.txt" "risultati" "mappatura_servizi.csv"
   ```

## Adapting the Script to New Data Extracts

- Only change the file path in `configurazione.R` or the first command-line argument.
- The `mappatura_servizi.csv` file maps each `servizio` code to an `ambito` (scope/category). The two included rows are **examples based on the ORL data extract only**: verify that C372 actually corresponds to the "Inpatient Admissions" scope in the organization's data. If codes change, update the mapping file, not the R code.
- Any code not included in the mapping remains visible as **"To be classified"** rather than being assigned arbitrarily.
- If the file uses an encoding other than UTF-8, change `codifica_testo` (e.g. `Windows-1252`).
- If an Excel file contains multiple worksheets, change `foglio_excel`.
- Statistical thresholds can be adjusted in the `config$soglia` list without modifying the functions.

## Average Calculation Logic

The unit of analysis is **service + product code + month**. Codes and descriptions are treated as text. Descriptions are not used as keys because they may change. If multiple rows exist for the same service/product/month combination, their values are summed.

- `media_mensile = quantita_totale / mesi_per_media`: includes months explicitly recorded with **zero** consumption.
- `media_mesi_con_consumo`: average quantity across months with **positive** consumption only (useful for occasional items; it does not replace the overall average).
- Calendar months with no records for a given service/product are generated **only between the first and last month in which the product appears**. They are flagged as `mese_assente = TRUE` and left as `NA` by default. They are not treated as zero consumption.
- To treat missing months as zero, set `imputa_mesi_mancanti_zero = TRUE`. This option should be used **only if the absence of a record genuinely means zero consumption**. The `mesi_rilevati` and `mesi_per_media` fields allow the denominator to be checked.
- Products that never appear in a given year are not automatically treated as having had zero consumption in that year.

## Quantities and Financial Values

- Costs with `quantita = 0` and `valore != 0` remain included in the **overall financial value**, but do not generate physical quantities.
- `VOCE_SOLO_ECONOMICA`: a product code with no positive quantitative consumption across the entire data extract. **This alone does not prove that the item is a management accounting allocation**: the code must be classified with the relevant department.
- `RETTIFICA_SENZA_QUANTITA`: a value-only entry for a product that also has positive quantitative consumption in other months.
- `QUANTITA_NON_VALORIZZATA` and `QUANTITA_NEGATIVA` are flagged for review; the data are not automatically corrected.
- Financial values include any positive or negative adjustments. The script separately produces `valore_con_quantita` and `valore_senza_quantita`.

## Outliers and Other Flags

- **Monthly outliers**: comparison with the historical behavior of the same `servizio + prodotto`, using a robust MAD threshold, IQR as an alternative, or the median of months with consumption if both methods return zero. At least 8 observed months and 4 months with positive quantities are required (parameters can be adjusted). Thresholds are conservative but do not constitute clinical validation.
- **Concentrated consumption**: more than 65% of the annual quantity occurring in a single month, subject to additional minimum volume/month requirements.
- **Year-over-year changes**: consecutive years are compared only across months present in both years, with a minimum of 6 comparable months. Example: January–September 2023 versus January–September 2024, rather than the whole of 2023 versus 9 months of 2024.
- **Unusual unit costs**: changes in the `valore/quantita` ratio compared with the product's historical median. A flag does not necessarily indicate a change in the purchase price, because the value may include adjustments.

Thresholds are initial parameters and should be calibrated with the Pharmacy, Supplies and Logistics, and Management Control departments. Where possible, comparisons with admissions/procedures should also be performed to obtain indicators related to clinical activity.

**Important:** total quantities for different products are not added together in reports by scope/category, because units of measure may differ (pieces, packages, ml, etc.).

## Output

The following files are generated in the `risultati` folder:

- `analisi_consumi.xlsx`: reconciliation of totals against the input data, summary reports, averages by year and for the entire period, outliers, variations, concentration analysis, financial anomalies, costs without quantities, financial-only entries, missing months, unclassified codes, and imported data.
- `outlier_mensili.csv`, `variazioni_annue.csv` for subsequent use.
- `valore_mensile_ambiti.png`, `quantita_top_prodotti.png` for visualization.

## Checks and Limitations

- Required columns and year/month values must be valid. No invalid row is silently discarded: the script stops and reports the rows that need to be corrected.
- Units of measure are **not included in the input data**. The system can compare quantities for the same product code, but cannot claim that different codes refer to the same unit of measure.
- The median and outliers refer to the entire period contained in the file. If there are significant structural changes in activity, consider segment-based analysis or normalization by the number of procedures.
- Product codes may change over time while still representing the same material. Without a code-equivalence table, they are treated as distinct products.
- Classification by scope/category depends on the mapping validated by the user.
