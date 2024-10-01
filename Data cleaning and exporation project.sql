-- WORLD LIFE EXPECTANCY PROJECT
-- PART #1 - Data cleaning

USE world_life_expectancy;

SELECT * 
FROM world_life_expectancy;


# Creating a back up copy of the data

# Checking Duplicates by creating a unique column
SELECT Country,
	   Year,
       CONCAT(Country, Year),
	   COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, 
		 Year,
         CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

# - Found 3 duplicates 

# Identifying row numbers for duplicates values
SELECT *
FROM (
		SELECT Row_id,
			   CONCAT(Country, Year),
			   ROW_NUMBER () OVER(PARTITION BY  CONCAT(Country, Year) ORDER BY  CONCAT(Country, Year)) AS row_num
		FROM world_life_expectancy
	 ) AS row_table
WHERE row_num > 1;

# Deleting 3 duplicates
DELETE FROM world_life_expectancy
WHERE row_id IN (
				SELECT row_id
				FROM (
						SELECT Row_id,
						CONCAT(Country, Year),
						ROW_NUMBER () OVER(PARTITION BY  CONCAT(Country, Year) ORDER BY  CONCAT(Country, Year)) AS row_num
						FROM world_life_expectancy
						) AS row_table
				WHERE row_num > 1
                    );
# Figuring out blanks in the column 'status'
SELECT * 
FROM world_life_expectancy
WHERE status = '';

# Determing types of status
SELECT DISTINCT(status) 
FROM world_life_expectancy
WHERE status <> '';

# Updating the table when status is blank
UPDATE world_life_expectancy as t1
JOIN world_life_expectancy as t2
	ON t1.country = t2.country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developing'; 

# Checking how the table was updated
SELECT * 
FROM world_life_expectancy
WHERE status = '';

# One row was not updated
SELECT * 
FROM world_life_expectancy
WHERE country = 'United States of America';

# Again, updating the table when status is blank
UPDATE world_life_expectancy as t1
JOIN world_life_expectancy as t2
	ON t1.country = t2.country
SET t1.status = 'Developed'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developed';

# Just in case want to make sure I have no nulls
SELECT * 
FROM world_life_expectancy
WHERE status IS NULL; 

# Switching to the column World Life Expextancy looking for blanks
SELECT * 
FROM world_life_expectancy
WHERE `Life expectancy` = '';

#Populating blanks in the column World Life Expextancy based on average
-- Computing average
SELECT t1.country, t1.year, t1.`Life expectancy`,
	   t2.country, t2.year, t2.`Life expectancy`,
	   t3.country, t3.year, t3.`Life expectancy`,
       ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy as t1
JOIN world_life_expectancy as t2
	ON t1.country = t2.country
    AND t1.year = t2.year - 1
    JOIN world_life_expectancy as t3
	ON t1.country = t3.country
    AND t1.year = t3.year + 1
WHERE t1.`Life expectancy` = '';

# Updating the blanks
UPDATE world_life_expectancy as t1
JOIN world_life_expectancy as t2
	ON t1.country = t2.country
    AND t1.year = t2.year - 1
    JOIN world_life_expectancy as t3
	ON t1.country = t3.country
    AND t1.year = t3.year + 1
SET t1.`Life expectancy` =  ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = '';


-- PART #2 - Data exploration

SELECT * 
FROM world_life_expectancy;

# Satisfying my owm curioisity with mininimum and maximum life expectancy by country 
SELECT country,  
MIN(`Life expectancy`) as min_life_expectancy,
MAX(`Life expectancy`) as max_life_expectancy
FROM world_life_expectancy
GROUP BY country
ORDER BY country DESC;

#Found some countries with no data about life expextancy. Filter them out.
SELECT country,  
MIN(`Life expectancy`) as min_life_expectancy,
MAX(`Life expectancy`) as max_life_expectancy
FROM world_life_expectancy
GROUP BY country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY country DESC;

#Calculate improvement in life expectancy
SELECT country, 
MIN(`Life expectancy`) as min_life_expectancy,
MAX(`Life expectancy`) as max_life_expectancy, 
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) as improvement_in_life_expectancy_over_15_years
FROM world_life_expectancy
GROUP BY country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY improvement_in_life_expectancy_over_15_years DESC;

#Understanding average life expectancy by years
SELECT year,  
ROUND(AVG(`Life expectancy`),1) as average_life_expectancy
FROM world_life_expectancy
WHERE `Life expectancy` <> 0
GROUP BY year
ORDER BY year;

#Correlation between GDP and life expectancy among countries
SELECT country, 
ROUND(AVG(`Life expectancy`),1) as average_life_expectancy,
ROUND(AVG(gdp),1) as average_gdp
FROM world_life_expectancy
GROUP BY country
HAVING average_life_expectancy > 0
AND average_gdp > 0
ORDER BY average_gdp DESC;

#Life expectancy between countries with high and low gdp
SELECT
SUM(CASE WHEN gdp >= 1500 THEN 1 ELSE NULL END) as high_gdp_count,
ROUND(AVG(CASE WHEN gdp >= 1500 THEN `Life expectancy` ELSE NULL END),1) as high_gdp_life_expectancy,
SUM(CASE WHEN gdp <= 1500 THEN 1 ELSE NULL END) as low_gdp_count,
ROUND(AVG(CASE WHEN gdp <= 1500 THEN `Life expectancy` ELSE NULL END),1) as low_gdp_life_expectancy
FROM world_life_expectancy;

#Comparing average life expectancy between developing and developed countries
SELECT status,
ROUND(AVG(`Life expectancy`),1) as average_life_expectancy
FROM world_life_expectancy
GROUP BY status;

# Something is off, countries with the developing status significantly overweight developed countries 
SELECT status, COUNT(DISTINCT country)
FROM world_life_expectancy
GROUP BY status;

#Comparison of the conclusion above
SELECT status, 
COUNT(DISTINCT country),
ROUND(AVG(`Life expectancy`),1) as average_life_expectancy
FROM world_life_expectancy
GROUP BY status;


#Getting understading of correlation between average life expectancy and bmi
SELECT country, 
ROUND(AVG(`Life expectancy`),1) as average_life_expectancy,
ROUND(AVG(bmi),1) as average_bmi
FROM world_life_expectancy
GROUP BY country
HAVING average_life_expectancy > 0
AND average_bmi > 0
ORDER BY average_bmi ASC;

#Rolling total of adult mortality
SELECT country, year, `Life expectancy`, `Adult mortality`,
SUM(`Adult mortality`) OVER(PARTITION BY country ORDER BY year) as rolling_total
FROM world_life_expectancy
;
#Checking the same but in US only
SELECT country, year, `Life expectancy`, `Adult mortality`,
SUM(`Adult mortality`) OVER(PARTITION BY country ORDER BY year) as rolling_total
FROM world_life_expectancy
WHERE country = 'United States of America';
















































