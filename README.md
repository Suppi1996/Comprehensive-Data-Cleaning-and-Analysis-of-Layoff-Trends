# Analyzing Layoffs Data: A Comprehensive Data Cleaning and Analysis Journey

In today’s data-driven world, understanding trends in workforce dynamics is crucial. 
This article delves into a dataset capturing layoffs across various industries, showcasing a meticulous process of data cleaning and exploratory data analysis. We will explore the journey of transforming raw data into actionable insights using SQL.

## Introduction
Layoffs can have significant impacts on economies and communities. This analysis aims to provide a clearer picture of recent layoffs, focusing on key metrics like the total number of layoffs and the affected industries. 
To start, we loaded the layoffs data into our SQL environment and began with some preliminary exploration.


-- Viewing the initial data

SELECT * FROM W_LAYOFFS..layoffs;

![image](https://github.com/user-attachments/assets/d111886d-2afd-4191-af4c-cff46f622ea5)


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

![image](https://github.com/user-attachments/assets/b959cbaf-fae3-473e-8840-fd84c3b5c14e)


### Company Analysis

We explored which companies had laid off the most employees.


SELECT company, SUM(total_laid_off) AS total_laid_off 
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

![image](https://github.com/user-attachments/assets/b35f9f7c-bf92-42e1-9474-46f7cb6588d2)


### Industry and Country Analysis

Understanding layoffs by industry and country provides valuable insights into market trends.


SELECT industry, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;

![image](https://github.com/user-attachments/assets/7116fa90-e518-427b-8858-9b52fe9d9fe0)

SELECT country, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

![image](https://github.com/user-attachments/assets/66c76466-49d5-40c9-9a38-9b4ea5cdcac2)


### Temporal Analysis

Analyzing layoffs over time helps identify trends and patterns. We summarized the total layoffs by year and month.


### Yearly layoffs
SELECT YEAR(date) AS year, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY SUM(total_laid_off) DESC;

![image](https://github.com/user-attachments/assets/e2a6b721-9617-41bf-bbf2-d1a82a2eeaa3)


### Monthly layoffs
SELECT FORMAT(date, 'yyyy-MM') AS month, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY FORMAT(date, 'yyyy-MM')
ORDER BY month ASC;

![image](https://github.com/user-attachments/assets/d5c352d2-1df3-4918-972a-c9b891cedc6e)

### Rolling total number of laid_offs

WITH cte AS (
    SELECT CAST(FORMAT(date, 'yyyy-MM') AS VARCHAR(7)) AS month, 
           SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY FORMAT(date, 'yyyy-MM')
)
SELECT month, 
       total_laid_off, 
       SUM(total_laid_off) OVER (ORDER BY month ASC) AS cumulative_total_laid_off
FROM cte
ORDER BY month ASC;

![image](https://github.com/user-attachments/assets/01b17e71-8f9d-4712-8759-a6edf420b288)

### Grouping by company and year

select company,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4)) AS year ,sum(total_laid_off) as laid_off from layoffs_staging2
group by company ,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4))
order by 1 asc;
![image](https://github.com/user-attachments/assets/9766b80a-5c05-4af2-8916-1e06d628442a)

## which company has large number of laid_offs based on year
with cte as(select company,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4)) AS year ,sum(total_laid_off) as laid_off from layoffs_staging2
group by company ,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4)))
select * ,dense_rank() over (partition by year order by laid_off desc) as rank from cte;
![image](https://github.com/user-attachments/assets/6250f9ed-c081-46bd-b378-2f9057f59595)

### Conclusion and Key Learnings
In this analysis, we’ve learned the importance of data cleaning and the impact it has on the quality of our insights. By removing duplicates, standardizing our dataset, and addressing null values, we laid a strong foundation for our exploratory analysis.

The insights derived from the cleaned data can help stakeholders understand layoff trends better, potentially informing future business strategies and decisions.


