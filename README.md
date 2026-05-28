## End-to-End Automation Pipeline
In longitudinal behavioral experiments, raw data is often scattered across dozens of unstructured daily `.xlsx` files filled with tracking noise. This repository features a single, unified `WinShift_EndToEnd_Pipeline.m` script that automates the entire data lifecycle:
1. **Automated Merging & Extraction:** Batch-processes all daily session files, computing key spatial metrics (Error Rank, First-4 Accuracy, Clockwise Index) while dynamically bypassing irrelevant columns.
2. **Dynamic Spatial Mapping:** Employs a `switch` logic to automatically update the correct target arms (baited arms) based on the specific session day, preventing hardcoding errors.
3. **Regex Chronological Sorting:** Utilizes Regular Expressions to extract the true session day from file nomenclatures, overriding default OS alphabetical sorting. It compiles a highly organized Master Dataset hierarchically sorted by Day, Subject, and Trial Phase.

---

## Data Privacy & Availability
**Please note:** This repository contains exclusively the data processing logic and MATLAB scripts. The dataset remains confidential to protect the integrity of the upcoming scientific publication.
