# R Coding | Data Analytics & Decision Support

This repository contains projects and experiments developed with **R**, with a focus on data analysis, data quality, statistical processing, and decision support.

The main objective is to transform raw data into structured information that can help identify trends, detect anomalies, and support operational and managerial decisions.

## Projects

### 1. Healthcare Consumption Analysis

A data analysis project focused on monitoring healthcare consumption and its economic implications.

The project is organized into separate scripts for configuration, data processing, reusable functions, and testing.

**Main capabilities include:**
- Importing and processing structured data.
- Analyzing consumption trends over time.
- Handling missing months and incomplete data.
- Identifying quantitative and economic anomalies.
- Monitoring changes in unit costs.
- Performing consistency and reconciliation checks.
- Supporting the interpretation of results through structured outputs.

**Project structure:**

```text
Analisi-consumi/
├── README.md
├── analisi_consumi.R
├── configurazione.R
├── funzioni_consumi.R
├── mappatura_servizi.csv
└── test_dati_sintetici.R
```

The separation between configuration, processing logic, and reusable functions is intended to make the project easier to maintain and adapt.

**Important analytical considerations**

The analysis distinguishes between missing data and zero consumption. These situations have different meanings and should not be treated as equivalent.

Similarly, a change in unit cost does not necessarily indicate a change in the purchase price: the interpretation depends on the underlying data and the assumptions adopted.

The results should therefore be considered analytical indicators rather than automatic evidence of causality.

### 2. Skill-Lab

A collection of R exercises and learning activities developed to explore programming techniques and data analysis.

## Approach

The projects in this repository follow a practical analytical approach:

1. Understand the data and its structure.
2. Define the analytical questions.
3. Validate data quality and consistency.
4. Apply appropriate processing and analytical methods.
5. Interpret the results in their operational context.

## Technologies

- R
- Structured data processing
- CSV files
- Statistical and quantitative analysis

## Data & Privacy

Examples and test activities should use synthetic or appropriately anonymized data.

No confidential healthcare, patient, employee, supplier, or organizational information should be included in this repository.

## Development Status

This repository contains analytical projects and learning activities. The presence of a script or analytical workflow does not imply that it has been validated for production use.

Further improvements may include additional automated tests, reproducible examples, and standardized output documentation.
