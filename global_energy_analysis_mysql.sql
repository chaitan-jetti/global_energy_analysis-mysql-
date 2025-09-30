CREATE DATABASE ENERGYDB;
USE ENERGYDB;

-- 1. COUNTRY TABLE
CREATE TABLE country_1(
    CID VARCHAR(10) PRIMARY KEY,
    country VARCHAR(100) UNIQUE
);

SELECT * FROM country_1;

-- 2. consumption table
CREATE TABLE consumption_01 (
	country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country_1(country)
);

SELECT * FROM consumption_01;

-- 3. production table
CREATE TABLE production_01 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country_1(country)
);

SELECT * FROM production_01 ;

-- 4. emission_3 table
CREATE TABLE emission_01 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country_1(country)
);

SELECT * FROM emission_01;

-- 5. gdp table
CREATE TABLE gdp_01 (
    country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (country) REFERENCES country_1(country)
);

SELECT * FROM gdp_01;

-- 6. population table
CREATE TABLE population_01 (
    country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (country) REFERENCES country_1(Country)
);

SELECT * FROM population_01;


#-- DATA ANALYSIS QUESTIONS

#-- General & Comparative Analysis


# 1.What is the total emission per country for the most recent year available?

-- Total emission per country for the most recent year
SELECT country,year,
SUM(emission) AS total_emission
FROM emission_01
WHERE year = (SELECT MAX(year) FROM emission_01)
GROUP BY country, year
ORDER BY total_emission DESC;


# 2. What are the top 5 countries by GDP in the most recent year?

SELECT country, year, value
FROM gdp_01
WHERE year = (SELECT MAX(year) FROM gdp_01)
ORDER BY value DESC
LIMIT 5;


# 3. Which energy types contribute most to emissions across all countries?

SELECT energy_type, SUM(emission) AS total_emission
FROM emission_01
GROUP BY energy_type
ORDER BY total_emission DESC;


--  TREND ANALYSIS OVER TIME

# 4. How have global emissions changed year over year?

SELECT year, SUM(emission) AS total_emission
FROM emission_01
GROUP BY year
ORDER BY year;

# 5. What is the trend in GDP for each country over the given years? 

SELECT country,year,value AS GDP,
LAG(value) OVER (PARTITION BY country ORDER BY year) AS prevyear_gdp,
(value - LAG(value) OVER (PARTITION BY country ORDER BY year)) AS gdp_change
FROM gdp_01
ORDER BY country, year;

# 6.How has population growth affected total emissions in each country?

SELECT 
p.country,p.year,p.Value as population,
SUM(e.emission) as total_emissions
FROM population_01 as p
JOIN emission_01 as e ON p.country = e.country AND p.year = e.year
GROUP BY p.country, p.year, p.Value
ORDER BY p.country, p.year;


# 7. Has energy consumption increased or decreased over the years for major economies?
SELECT c.country, c.year, SUM(c.consumption) AS total_consumption
FROM consumption_01 c
JOIN (
    SELECT country
    FROM gdp_01
    WHERE year = (SELECT MAX(year) FROM gdp_01)
    ORDER BY value DESC
    LIMIT 5
) AS top5
ON c.country = top5.country
GROUP BY c.country, c.year
ORDER BY c.country, c.year;



-- 8. What is the average yearly change in emissions per capita for each country?

SELECT 
e1.country AS "Country Name",
ROUND(AVG(e2.PER_CAPITA_EMISSION - e1.PER_CAPITA_EMISSION), 4) AS "Average Yearly Change in Per Capita Emissions "
FROM emission_01 as e1
JOIN emission_01 as e2
ON e1.country = e2.country AND e2.Year = e1.Year + 1
GROUP BY e1.Country
ORDER BY "Average Yearly Change in Per Capita Emissions " DESC;


-- RATIO & PER CAPITAL ANALYSIS

# 9. What is the emission-to-GDP ratio for each country by year?

SELECT
 e.country, e.year, e.emission,
 g.value AS GDP,(e.emission * 1.0 / g.value) AS emission_to_GDP_ratio
FROM emission_01 as e
JOIN gdp_01 as g ON e.country = g.country AND e.year = g.year
ORDER BY e.country, e.year;

# 10. What is the energy consumption per capita for each country over the last decade?

SELECT c.country,c.year,
ROUND(SUM(c.consumption) / p.population, 4) 
AS per_capita_consumption
FROM 
(SELECT country, year, SUM(consumption) 
AS consumption
FROM consumption_01
GROUP BY country, year) AS c
JOIN 
(SELECT country, year, MAX(value) AS population
    FROM population_01
    GROUP BY country, year) AS p
ON c.country = p.country
AND c.year = p.year
WHERE c.year BETWEEN 2020 AND 2023
GROUP BY c.country, c.year, p.population
ORDER BY c.country, c.year;



# 11. How does energy production per capita vary across countries?

SELECT p.country AS Country,p.year AS Year,
SUM(p.production) AS Total_Production,
pop.value AS Population,
ROUND(SUM(p.production) / pop.value, 6) AS Production_per_Capita
FROM production_01 AS p
JOIN population_01 AS pop 
ON p.country = pop.country
AND p.year = pop.year
GROUP BY p.country, p.year, pop.value
ORDER BY p.country, p.year;


#12.Which countries have the highest energy consumption relative to GDP?
SELECT c.country,c.year,
SUM(c.consumption) AS total_consumption,
MAX(g.value) AS gdp,
ROUND(SUM(c.consumption) / MAX(g.value), 
6) AS consumption_per_gdp
FROM consumption_01 c
JOIN gdp_01 g 
ON c.country = g.country 
 AND c.year = g.year
GROUP BY c.country, c.year
ORDER BY consumption_per_gdp DESC;


#13.What is the correlation between GDP growth and energy production growth?

WITH gdp_growth AS (SELECT g1.country,
g1.year,((g1.Value - g2.Value) / g2.Value * 100) 
as gdp_growth
FROM gdp_01 g1
JOIN gdp_01 g2 ON g1.country = g2.country AND g1.year = g2.year + 1),
energy_growth AS (SELECT p1.country,
p1.year,((SUM(p1.production) - SUM(p2.production)) / SUM(p2.production) * 100) 
as energy_growth
FROM production_01 p1
JOIN production_01 p2 ON p1.country = p2.country AND p1.year = p2.year + 1
GROUP BY p1.country, p1.year)
SELECT g.country,g.year,ROUND(g.gdp_growth, 2) as gdp_growth,
ROUND(e.energy_growth, 2) as energy_growth
FROM gdp_growth g
JOIN energy_growth e ON g.country = e.country AND g.year = e.year
ORDER BY g.country, g.year;



-- GLOBAL COMPARISONS

# 14. What are the top 10 countries by population and how do their emissions compare

SELECT 
p.country AS Country,
p.Value AS Population,
ROUND(SUM(e.per_capita_emission * p.Value), 2) AS Total_Emission,
ROUND(AVG(e.per_capita_emission), 4) AS Per_Capita_Emission
FROM population_01 as p
JOIN emission_01 as e 
ON p.country = e.country
WHERE p.year = (SELECT MAX(year) FROM population_01)
AND e.year = (SELECT MAX(year) FROM emission_01)
GROUP BY p.country, p.Value
ORDER BY p.Value DESC
LIMIT 10;


-- 15. what is the Global share (%) of emissions by country
SELECT 
country,SUM(emission) AS country_emission,
ROUND(SUM(emission) / (SELECT SUM(emission) FROM emission_01) * 100, 2)
 AS global_share_percent
FROM emission_01
GROUP BY country
ORDER BY global_share_percent DESC;


# 16. What is the global average GDP, emission, and population by year?
SELECT
 g.YEAR,
 G.AVG_GDP,
 E.AVG_EMISSIONS,
 P.AVG_POPULATION
 
 FROM (
SELECT YEAR,AVG(value) AS AVG_GDP
FROM gdp_01
GROUP BY YEAR) g
JOIN
(SELECT YEAR,AVG(emission) AS AVG_EMISSIONS
FROM emission_01
GROUP BY YEAR) E ON g.YEAR = E.YEAR
JOIN
( SELECT YEAR,AVG(value) AS AVG_POPULATION
FROM population_01
GROUP BY YEAR) P ON g.YEAR = P.YEAR
ORDER BY g.YEAR;







