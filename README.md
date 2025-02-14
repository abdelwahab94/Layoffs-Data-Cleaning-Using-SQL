# Data Cleaning in SQL

## 📌 Project Overview
This project involves cleaning and standardizing data in the `layoffs` dataset using SQL. The cleaning process includes:
- Removing duplicates
- Standardizing data formats
- Handling null and blank values
- Removing unnecessary columns

---
## 📂 Database Tables

### 1️⃣ **`layoffs`** (Original Table)
This table contains raw data related to company layoffs, including fields such as:
- `company` (TEXT) - Name of the company
- `location` (TEXT) - Company location
- `industry` (TEXT) - Industry sector
- `total_laid_off` (INT) - Number of employees laid off
- `percentage_laid_off` (TEXT) - Layoff percentage
- `date` (TEXT) - Date of layoff event
- `stage` (TEXT) - Company growth stage
- `country` (TEXT) - Country of the company
- `funds_raised_millions` (INT) - Total funds raised in millions

### 2️⃣ **`layoffs_staging`** (Staging Table)
A copy of `layoffs` used for cleaning and transformation.

### 3️⃣ **`layoffs_staging2`** (Final Cleaned Table)
An enhanced version of `layoffs_staging` where duplicates are removed and data is cleaned.

---
## 🛠️ Data Cleaning Steps

### **1️⃣ Removing Duplicates**
#### ✅ Identify duplicates using `ROW_NUMBER()`
```sql
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;
```
#### ✅ Delete duplicate records
```sql
DELETE FROM layoffs_staging2
WHERE row_num > 1;
```
---
### **2️⃣ Standardizing Data**
#### ✅ Trim spaces from `company` names
```sql
UPDATE layoffs_staging2
SET company = TRIM(company);
```
#### ✅ Normalize `industry` values (e.g., standardizing "crypto" variations)
```sql
UPDATE layoffs_staging2
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';
```
#### ✅ Remove trailing dots in `country`
```sql
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);
```
#### ✅ Convert `date` column to `DATE` format
```sql
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```
---
### **3️⃣ Handling NULL & Blank Values**
#### ✅ Replace blank industry values with NULL
```sql
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
```
#### ✅ Fill missing `industry` values based on existing company data
```sql
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
```
#### ✅ Remove records where both `total_laid_off` and `percentage_laid_off` are NULL
```sql
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
```
---
### **4️⃣ Removing Unnecessary Columns**
#### ✅ Drop the `row_num` column after duplicate removal
```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```
---
## 🔍 Final Verification
After cleaning, we verify the final dataset:
```sql
SELECT * FROM layoffs_staging2;
```
---
## 📊 Summary
✅ **Duplicates Removed**
✅ **Standardized Data Formats**
✅ **Handled NULL and Blank Values**
✅ **Removed Unnecessary Columns**

This cleaned dataset is now ready for **further analysis and reporting.** 🚀
