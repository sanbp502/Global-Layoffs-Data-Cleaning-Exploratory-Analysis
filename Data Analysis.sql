/*
Project: World Layoffs Data Analysis

Description:
This project demonstrates common data analysis techniques using layoffs data
from multiple companies in different countries

Objectives:
- Identify trends and draw insights from company layoffs
*/

SELECT *
FROM layoffs_staging2
;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions  DESC
;
-- The query selects companies that raised the highest amount of money and fully shut down

WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company) AS row_num
FROM layoffs_staging2 
)
SELECT * FROM duplicate_cte WHERE row_num > 1 AND percentage_laid_off = 1
;

-- The query selects companies that had multiple instances of layoffs and still ended up shutting down. 
-- Potential case studies for market failure by area, industry, management etc.

-- Both queries above highlight potential market inefficiencies where factors forced shutdown of the company regardless of funds raised
-- With some companies undergoing multiple instances of downsizing with the same result

SELECT stage, SUM(total_laid_off) AS total_laid_off, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY stage
ORDER BY avg_layoffs DESC
;

-- Query selects total layoffs by stage, as well as the average layoffs per layoff instance in order to comprehend approximate sizes of layoffs by company stage

WITH Stage_Counts AS (
	SELECT
		stage,
		COUNT(DISTINCT company) AS total_companies,
		COUNT(DISTINCT CASE
			WHEN percentage_laid_off = 1 THEN company
		END) AS companies_under
	FROM layoffs_staging2
	GROUP BY stage
    )
SELECT stage, total_companies, companies_under,
ROUND(companies_under / total_companies * 100, 2) AS went_under_percent
FROM Stage_Counts
ORDER BY went_under_percent DESC
;

-- The query selects the total number of distinct companies, as well as the number of distinct companies that went under
-- The query then calculates the percentage of companies that went under by stage

-- The analysis shows a normalized version of failure rates depending on the stage of a company, which can contribute insights into
-- which funding stages may result in shutdowns. Seed stages showing higher failure rate even if layoffs are smaller, while Post-IPO companies
-- deliver larger layoffs, but rarely go under which follows general risk profiles of a company's funding lifecycle.

SELECT industry, SUM(total_laid_off) AS total_laid_off, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY industry
ORDER BY avg_layoffs DESC
;

-- Query selects total layoffs by industry, as well as the average layoffs per layoff instance in order to comprehend approximate sizes of layoffs by industry

WITH Industry_Counts AS (
	SELECT
		industry,
		COUNT(DISTINCT company) AS total_companies,
		COUNT(DISTINCT CASE
			WHEN percentage_laid_off = 1 THEN company
		END) AS companies_under
	FROM layoffs_staging2
	GROUP BY industry
    )
SELECT industry, total_companies, companies_under,
ROUND(companies_under / total_companies * 100, 2) AS went_under_percent
FROM Industry_Counts
ORDER BY went_under_percent DESC
;

-- The query selects the total number of distinct companies, as well as the number of distinct companies that went under
-- The query then calculates the percentage of companies that went under by industry

-- The analysis shows a normalized version of failure rates depending on the industry, which can contribute insights into
-- which industries were impacted the most during a global pandemic event. Food and education industries had a considerable sample size and went under the most,
-- while aerospace had one of its 3 instances shut down but a more significant sample size for this industry would give better insights. Industries that fared the best (sub 5% shutdown rate)
-- included healthcare, marketing, logistics, HR, security, and data, with other fields having a 0% shutdown rate, but potentially unreliable due to smaller sample sizes.

SELECT YEAR(`date`) `year`, COUNT(DISTINCT MONTH(`date`)) months,  SUM(total_laid_off) layoffs, AVG(total_laid_off) avg_layoff_event
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
;

-- The query selects each year in the dataset and provides months of data available within each year for context
-- The query also shows layoffs for the year and the average layoff event

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH` `month`, total_off, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total
;
-- The query shows layoffs per month, as well as keeping a rolling total adding each month

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
ORDER BY years
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;

-- The query ranks the top 5 companies per year that had the most layoffs ordered by year

-- Together, the above queries give insights into which years had the biggest impact in layoff size, as well as identifying specific months in which there were more layoffs than usual
-- Notable insights include the rapid growth in layoffs starting from November of 2022 through the end of the dataset on March 2023
-- Only 5 months were responsible for 189,457, or 49.4% of all layoffs, showing a rapidly increasing trend for potential forecasting
-- Amazon ranked in the top 5 for both 2022 and 2023, contributing to the large numbers, along with techn-heavy companies like Meta, Google, and Microsoft