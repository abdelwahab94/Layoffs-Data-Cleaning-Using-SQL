-- ====================================
-- DATA CLEANING SCRIPT
-- ====================================

-- Step 1: Create a Staging Table for Cleaning Process

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging 
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging;

-- ====================================
-- STEP 1: REMOVING DUPLICATES
-- ====================================

-- Identify duplicates using ROW_NUMBER()

SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte 
WHERE row_num > 1;

-- Verify duplicates for a specific company
SELECT * FROM layoffs_staging WHERE company = 'hibob';

-- Create a new table to remove duplicates (since CTEs don't support DELETE)
CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Verify duplicate rows
SELECT * FROM layoffs_staging2 WHERE row_num > 1;

-- Delete duplicate rows
DELETE FROM layoffs_staging2 WHERE row_num > 1;

-- ====================================
-- STEP 2: STANDARDIZING DATA
-- ====================================

-- Trim extra spaces in company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize industry names (Example: Crypto variations)
UPDATE layoffs_staging2
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

-- Verify location data
SELECT DISTINCT(location) FROM layoffs_staging2 ORDER BY 1;

-- Standardize country names (remove trailing dots)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Convert `date` column from TEXT to DATE format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modify column type to enforce DATE format
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ====================================
-- STEP 3: HANDLING NULL & BLANK VALUES
-- ====================================

-- Identify NULL or blank values in the industry column
SELECT * FROM layoffs_staging2 
WHERE industry IS NULL OR industry = '';

-- Replace blank industry values with NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing industry values using data from the same company
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Verify if there are still NULL values
SELECT * FROM layoffs_staging2 
WHERE industry IS NULL OR industry = '';

-- Identify and delete rows where both total_laid_off and percentage_laid_off are NULL
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- ====================================
-- STEP 4: REMOVE UNNECESSARY COLUMNS
-- ====================================

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final verification of cleaned data
SELECT * FROM layoffs_staging2;
