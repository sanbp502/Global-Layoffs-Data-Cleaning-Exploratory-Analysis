/*
Project: World Layoffs Data Cleanup

Description:
This project demonstrates common data cleaning techniques using layoffs data
from multiple companies in different countries between 2020 and 2023.

Objectives:
- Identify and remove duplicates
- Standardize the data
- Handle NULL or blank values
- Remove or ignore unnecessary columns when relevant
*/

-- Ensure correct schema
USE world_layoffs
;

-- Verify data integrity
SELECT *
FROM layoffs
;

-- Create staging table to perform data cleaning separately from raw data
CREATE TABLE layoffs_staging
LIKE layoffs
;

INSERT layoffs_staging
SELECT *
FROM layoffs
;

SELECT *
FROM layoffs_staging
;
-- =========================
-- Identify Duplicates
-- =========================

-- No unique identification number is present, so partitioning using row number can reveal duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging
;

-- CTE can now filter results

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
;
-- =========================
-- Delete Duplicates
-- =========================

-- MySQL limitation prevents direct use of DELETE from a CTE. A second staging table is created to delete the duplicates. 
-- Alternatively creating an auto-increment primary key as an identifier, then deleting using a self-join could work as well

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1
;

DELETE
FROM layoffs_staging2
WHERE row_num > 1
;

-- The SELECT statement allows me to monitor the duplicates before and after using the DELETE statement, which removes them from the new staging table

-- =========================
-- Standardize Data
-- =========================
-- Each column will be updated according to its needs and data types in order to standardize information for processing. The column is first selected and then updated

SELECT DISTINCT company
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET company = TRIM(company)
;
-- 'company' column required TRIM to eliminate white space at the ends of the names

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1
;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'
;
-- 'industry' column required consolidation of overlapping industries under a different name. Crypto-like industries consolidated for analysis

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1
;
-- No change necessary for 'location' column

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1
;

SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%'
;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1
;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'
;
-- 'country' column had a duplicate entry with a '.' at the end. Used trailing TRIM to delete '.' at the end of 'United States'-like entries. Alternatively, a REPLACE function could have been used for this

SELECT `date`
FROM layoffs_staging2;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`= STR_TO_DATE(`date`, '%m/%d/%Y')
;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;

-- 'date' column was formatted as text. Formatted as date by using STR_TO_DATE, then converted data type from text to date
-- Remaining columns have no formatting issues

-- =========================
-- Identify blank and NULL spaces
-- =========================

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Some companies (Airbnb, Juul, and Carvana) have entries where industry is populated and blank in different entries
-- If applicable, empty industry spaces for matching companies can be populated by identifying the industry and performing a JOIN
-- Blank strings can be turned into NULL in order to update

SELECT *
FROM layoffs_staging2
WHERE industry = ''
OR industry IS NULL
;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''
;


SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
;

UPDATE  layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
;

SELECT * 
FROM layoffs_staging2 
WHERE company = 'Airbnb' 
OR company = 'Juul' 
OR company = 'Carvana'
;
-- 'industry' column has been populated where applicable with matching entries for the same company. Companies with no matching entries cannot be populated and will remain NULL

-- =========================
-- Purging unnecessary data
-- =========================

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Analysis on this dataset aims to convey information on layoffs. Entries with no data in layoffs in this case can be deemed unecessary or not trustworthy and could convolute results
-- These entries with NULL values on total layoffs and layoffs as a percentage are removed using DELETE

ALTER TABLE layoffs_staging2
DROP COLUMN row_num
;

-- Lastly, 'row_num' column, previously added to the second staging table can be deleted, as it is no longer necessary
-- This finalizes the cleanup process with the result being a clean dataset for analysis

SELECT *
FROM layoffs_staging2
ORDER BY 1
;