# Analyzing Layoffs Data: A Comprehensive Data Cleaning and Analysis Journey

In today’s data-driven world, understanding trends in workforce dynamics is crucial. 
This article delves into a dataset capturing layoffs across various industries, showcasing a meticulous process of data cleaning and exploratory data analysis. We will explore the journey of transforming raw data into actionable insights using SQL.

## Introduction
Layoffs can have significant impacts on economies and communities. This analysis aims to provide a clearer picture of recent layoffs, focusing on key metrics like the total number of layoffs and the affected industries. 
To start, we loaded the layoffs data into our SQL environment and began with some preliminary exploration.


-- Viewing the initial data
SELECT * FROM W_LAYOFFS..layoffs;


## Step 1: Data Cleaning

The first step in any data analysis is to clean the data. This involves removing duplicates, standardizing values, and handling missing data.

### Removing Duplicates

Duplicates can skew results and lead to incorrect insights. To identify and remove them, we utilized a Common Table Expression (CTE):


WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
                             ORDER BY (SELECT NULL)) AS row_num
    FROM layoffs_staging
)
SELECT * 
FROM cte 
WHERE row_num > 1;


### Creating a Staging Table

To work with cleaned data, we created a staging table to hold the refined records.


-- Creating a staging table
SELECT *
INTO layoffs_staging
FROM layoffs
WHERE 1 = 0;  -- No rows inserted yet


Next, we populated this table with data while identifying duplicates.


INSERT INTO layoffs_staging
SELECT * FROM layoffs;

--creating another staging table to delete duplicate records

USE [W_LAYOFFS]
GO

/****** Object:  Table [dbo].[layoffs_staging]    
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS [dbo].[layoffs_staging2]
CREATE TABLE [dbo].[layoffs_staging2](
	[company] [varchar](50) NULL,
	[location] [varchar](50) NULL,
	[industry] [varchar](50) NULL,
	[total_laid_off] [varchar](50) NULL,
	[percentage_laid_off] [varchar](50) NULL,
	[date] [varchar](50) NULL,
	[stage] [varchar](50) NULL,
	[country] [varchar](50) NULL,
	[funds_raised_millions] [varchar](50) NULL,
	row_number INT
) ON [PRIMARY]
GO

select * from layoffs_staging2;

INSERT INTO layoffs_staging2
 SELECT *,
           ROW_NUMBER() OVER(PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, date ,stage,country,funds_raised_millions
                             ORDER BY (SELECT NULL)) AS row_num
    FROM layoffs_staging;


select * from layoffs_staging2 where row_number>1;

--DELETING DUPLICATES
delete from layoffs_staging2 where row_number>1;

### Standardizing Data

Standardization is key to ensuring that our analyses are consistent. We trimmed whitespace from company names and standardized industry names.


UPDATE layoffs_staging2 SET company = TRIM(company);

-- Merging similar industries
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';


### Handling Null and Blank Values

We checked for null or blank values and replaced them where necessary.


-- Identifying NULL or blank values
SELECT * FROM layoffs_staging2 WHERE industry IS NULL;

UPDATE layoffs_staging2 SET industry = 'NULL' WHERE industry = ' ';


## Step 2: Converting Data Types

Next, we focused on converting data types to ensure they were appropriate for analysis. This included converting the date from a varchar to a date type.


-- Converting date from varchar to date
UPDATE layoffs_staging2 SET date = CONVERT(DATE, date, 101) WHERE TRY_CONVERT(DATE, date, 101) IS NOT NULL;


## Step 3: Exploratory Data Analysis (EDA)

With the data cleaned and standardized, we proceeded to exploratory data analysis. This step involves querying the data to uncover insights.

### Key Metrics

We started by calculating the maximum total layoffs and the percentage laid off.


SELECT MAX(total_laid_off), MAX(percentage_laid_off) FROM layoffs_staging2;


### Company Analysis

We explored which companies had laid off the most employees.


SELECT company, SUM(total_laid_off) AS total_laid_off 
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


### Industry and Country Analysis

Understanding layoffs by industry and country provides valuable insights into market trends.


SELECT industry, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;

SELECT country, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;


### Temporal Analysis

Analyzing layoffs over time helps identify trends and patterns. We summarized the total layoffs by year and month.


-- Yearly layoffs
SELECT YEAR(date) AS year, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY SUM(total_laid_off) DESC;

-- Monthly layoffs
SELECT FORMAT(date, 'yyyy-MM') AS month, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY FORMAT(date, 'yyyy-MM')
ORDER BY month ASC;


## Conclusion

This analysis of layoffs data highlights the importance of thorough data cleaning and exploratory analysis. By transforming raw data into structured insights, we can better understand the complexities of layoffs across various sectors. 

As industries continue to evolve, having a clear understanding of these trends will be essential for stakeholders at all levels.

---

### Publishing on GitHub Pages

1. **Create a new repository** on GitHub and enable GitHub Pages.
2. **Add a new Markdown file** (`analysis.md` or similar) and paste the content above into it.
3. **Commit and push** the changes.
4. Visit your GitHub Pages URL to see your formatted article.

Feel free to adjust the narrative or code snippets to better fit your style!
