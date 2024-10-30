-- DATA CLEANING

select * from W_LAYOFFS..layoffs;

--1. REMOVE DUPLICATES
--2. STANDARDIZE THE DATA 
--3. NULL or Blank Values
--4. Remove any Columns

--CREATING A STAGING TABLE

SELECT *
INTO layoffs_staging
FROM layoffs
WHERE 1 = 0;


select * from layoffs_staging;

--INSERTING DATA INTO STAGING 

INSERT INTO layoffs_staging
select * from  layoffs;

--Identifying duplicates

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, date ,stage,country,funds_raised_millions
                             ORDER BY (SELECT NULL)) AS row_num
    FROM layoffs_staging
)
SELECT * 
FROM cte 
WHERE row_num > 1;

select * from layoffs_staging where company='Casper';

--creating another staging table to delete duplicate records

USE [W_LAYOFFS]
GO

/****** Object:  Table [dbo].[layoffs_staging]    Script Date: 10/29/2024 11:00:38 AM ******/
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

--Standardizing the data(finding issues and fixing it)

--TRIM COMPANY NAME

UPDATE layoffs_staging2 set company=trim(company);


select distinct industry from layoffs_staging2 order by 1;
--MERGING ALL THE INDUSTRIES WHICH ARE SIMILAR

update layoffs_staging2  set industry='Crypto'
where industry like 'Crypto%';

--Checking the country column for issues

select distinct country from layoffs_staging2 order by 1;
--Updated the column because we have period at the end 
update layoffs_staging2 set country=TRIM(TRAILING '.' FROM COUNTRY);


--DATE SHOULD BE CHANGED BECAUSE WE DON'T WANT IT TO BE TEXT COLUMN 
SELECT date, 
       CONVERT(DATE, date, 101) AS converted_date
FROM layoffs_staging2
WHERE TRY_CONVERT(DATE, date, 101) IS NOT NULL;

update layoffs_staging2 set date=CONVERT(DATE, date, 101) WHERE TRY_CONVERT(DATE, date, 101) IS NOT NULL;

select * from layoffs_staging2;

--Changing the data type of data column
ALTER TABLE layoffs_staging2 alter column date DATE;

SELECT *
FROM layoffs_staging2
where date ='NULL';

delete FROM layoffs_staging2
where date ='NULL';


--WORKING WITH NULLS AND BLANKS

select * from layoffs_staging2 where total_laid_off = 'NULL'
and percentage_laid_off='NULL' ;

select * from layoffs_staging2 where company='Airbnb';

select * from layoffs_staging2 where industry IS NULL;

update layoffs_staging2 set industry = 'NULL' where  industry=' ';

select * from
layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company=t2.company
and t1.location=t2.location
where (t1.industry ='NULL' or t1.industry=' ')
and t2.industry IS NOT NULL;

UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 ON t1.company = t2.company
                             AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = ' ')
      AND t2.industry IS NOT NULL;

	  
--Deleting unwanted data

delete from layoffs_staging2 where total_laid_off = 'NULL'
and percentage_laid_off='NULL' ;

--Dropping unwanted columns

ALTER TABLE layoffs_staging2
DROP COLUMN row_number;

delete from layoffs_staging2 where total_laid_off ='NULL';
ALTER TABLE layoffs_staging2 alter column total_laid_off INT;
delete from layoffs_staging2 where  percentage_laid_off= 'NULL';
ALTER TABLE layoffs_staging2 alter column percentage_laid_off float;
--We have completed data cleaning till now

--Exploratory Data Analysis

select * from layoffs_staging2;

select max(total_laid_off),max(percentage_laid_off) from layoffs_staging2;

--CHECKING WHICH COMPANY HAS LAID OFF ALL THE EMPLOYEES

select * from layoffs_staging2 where percentage_laid_off=1 ;

--Checking which company has large number of laid offs
select company,sum(total_laid_off) from layoffs_staging2
group by company
order by 2 desc ;


select max(date),min(date) from layoffs_staging2;

--lets check which industry has more number of laid offs

select industry,sum(total_laid_off) from layoffs_staging2
group by industry
order by 2 desc ;

--lets check which country has more number of laid offs
select country,sum(total_laid_off) from layoffs_staging2
group by country
order by 2 desc ;

--Lets check by year how many people got laid_off
select year(date),sum(total_laid_off) from layoffs_staging2
group by year(date)
order by 2 desc ;

--Total number of laid_offs based on month and year
SELECT FORMAT(date, 'yyyy-MM') AS month, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY FORMAT(date, 'yyyy-MM')
ORDER BY 1 ASC;

--Rolling total number of laid_offs
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


--Grouping by company and year
select company,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4)) AS year ,sum(total_laid_off) as laid_off from layoffs_staging2
group by company ,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4))
order by 1 asc;
--which company has large number of laid_offs based on year
with cte as(select company,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4)) AS year ,sum(total_laid_off) as laid_off from layoffs_staging2
group by company ,CAST(FORMAT(date, 'yyyy') AS VARCHAR(4)))
select * ,dense_rank() over (partition by year order by laid_off desc) as rank from cte;
