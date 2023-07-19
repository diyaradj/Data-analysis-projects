# Data Analysis:

In this project I analyze data about COVID-19 from Our World in Data website using SQL quaries. 
This dataset contains 6 tables about new cases of COVID-19, demography in countries, 
new admissions to hospitals, locations included in the dataset, tests conducted, vaccinations. 
All tables are connected using variables: iso_code and date.
##### Cleaning the data
First, I clean the data: checking for duplicates in the data, for example, in Regions table.  
> ###### Query
```
SELECT r.iso_code, r.continent, r.location,
COUNT(*) AS checking_dup
FROM `da-nfactorial.covid19.regions` r
GROUP BY r.iso_code, r.continent, r.location
HAVING checking_dup > 1; 
```
Next, I check whether there are observations with iso_code that contain more than three characters as it is supposed to.
> ###### Query
```
SELECT c.iso_code
FROM `da-nfactorial.covid19.cases` c
WHERE c.iso_code NOT LIKE '___'
GROUP BY c.iso_code; 
```
##### Results
There are observations with code: "OWID_KOS".
Next, I remove text in brackets in countries' name.
> ###### Query
```
SELECT r.location,
CONCAT(
LEFT(r.location,STRPOS(r.location, '(')-1),' ',
RIGHT(r.location,LENGTH(r.location)-STRPOS(r.location, ')')))
FROM `da-nfactorial.covid19.regions` r
WHERE r.location LIKE '%(%)%'
GROUP BY r.location; 
```
I check whether data types are correct. In hospital table, variables: types weekly_icu_admissions, hosp_patients, weekly_hosp_admissions are STRING, while they are numbers and should be of type FLOAT. So I change the data type of these variables to FLOAT.
> ###### Query
```
SELECT *, 
CAST(h.weekly_icu_admissions AS FLOAT64) AS weekly_icu_admissions_new,
CAST(h.hosp_patients AS FLOAT64) AS hosp_patients_new,
CAST(h.weekly_hosp_admissions AS FLOAT64) AS weekly_hosp_admissions_new
FROM `da-nfactorial.covid19.hospital` h;
```
##### Analysis
##### Question 1: In which country probability of death of an infected person was the highest?
> ###### Query
```
WITH prob AS(
SELECT location, c.date, c.total_deaths, c.total_cases, ROUND((c.total_deaths/c.total_cases)*100,2) AS probability
FROM `da-nfactorial.covid19.cases` c
INNER JOIN `da-nfactorial.covid19.regions` r
ON c.iso_code=r.iso_code)

SELECT location, date, probability
FROM prob
WHERE probability=(SELECT MAX(probability) FROM prob)
ORDER BY date; 
```
###### Results
##### Question 2: What was the percentage of infected people and the percentage of people dying from COVID-19 in each country?
> ###### Query
```
WITH cte AS(
SELECT r.location, c.iso_code, 
SUM(c.new_cases) AS all_cases, SUM(c.new_deaths) AS all_deaths
FROM `da-nfactorial.covid19.cases` c
INNER JOIN `da-nfactorial.covid19.regions` r
ON c.iso_code=r.iso_code
GROUP BY c.iso_code, r.location)

SELECT location, all_cases, all_deaths, d.population,
ROUND((all_cases/d.population)*100,2) AS prob_ill,
ROUND((all_deaths/d.population)*100,2) AS prob_death
FROM cte cc
INNER JOIN `da-nfactorial.covid19.demography` d
ON cc.iso_code=d.iso_code 
ORDER BY prob_ill DESC; 
```
###### Results
##### Question 3: What was the percentage of infected people and the percentage of people dying from COVID-19 in the world?
> ###### Query
```
WITH cte AS(
SELECT  c.iso_code,
SUM(c.new_cases) AS all_cases, SUM(c.new_deaths) AS all_deaths
FROM `da-nfactorial.covid19.cases` c
INNER JOIN `da-nfactorial.covid19.regions` r
ON c.iso_code=r.iso_code
GROUP BY c.iso_code)

SELECT SUM(all_cases) AS total_cases, SUM(all_deaths) AS total_deaths, 
SUM(d.population) AS total_population,
ROUND((SUM(all_cases)/SUM(d.population))*100,2) AS prob_ill,
ROUND((SUM(all_deaths)/SUM(d.population))*100,2) AS prob_death
FROM cte cc
INNER JOIN `da-nfactorial.covid19.demography` d
ON cc.iso_code=d.iso_code; 
```
###### Results
##### Question 4: Which countries have coped well with COVID-19 treatment?
In this case, it is considered that a country have coped well with COVID-19 treatment if the most recent observation of the number of patients in the intensive care unit is smaller than the oldest observation of the number of patients in the intensive care unit.
> ###### Query
```
SELECT * FROM (
SELECT DISTINCT location,
ROW_NUMBER() OVER (PARTITION BY h.iso_code) AS row_num,
FIRST_VALUE(h.date) OVER (PARTITION BY h.iso_code ORDER BY h.date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_date,
FIRST_VALUE(IFNULL(h.icu_patients,0)) OVER (PARTITION BY h.iso_code ORDER BY h.date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_day_value,
LAST_VALUE(h.date) OVER (PARTITION BY h.iso_code ORDER BY h.date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_date,
LAST_VALUE(IFNULL(h.icu_patients,0)) OVER (PARTITION BY h.iso_code ORDER BY h.date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_day_value, 
(LAST_VALUE(IFNULL(h.icu_patients,0)) OVER (PARTITION BY h.iso_code ORDER BY h.date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) - (FIRST_VALUE(IFNULL(h.icu_patients,0)) OVER (PARTITION BY h.iso_code ORDER BY h.date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS diff
FROM `da-nfactorial.covid19.hospital` h
INNER JOIN `da-nfactorial.covid19.regions` r
ON h.iso_code=r.iso_code)
WHERE row_num=1
ORDER BY diff;
```
###### Results
##### Question 5: How did the number of new cases change on a daily basis in each country?
I estimate daily percentage change in new cases and add a new variable trend which shows whether percentage change increased/decreased/didn't change.
> ###### Query
```
WITH cte AS 
(SELECT r.location, c.date, c.new_cases, 
LAG(c.new_cases) OVER (PARTITION BY r.location ORDER BY c.date ASC) AS lag_new_cases,
100*(c.new_cases-LAG(c.new_cases) OVER (PARTITION BY r.location ORDER BY c.date))/NULLIF(LAG(c.new_cases) OVER (PARTITION BY c.iso_code ORDER BY c.date),0) AS rel_diff
FROM `da-nfactorial.covid19.cases` c
INNER JOIN `da-nfactorial.covid19.regions` r
ON c.iso_code=r.iso_code )

SELECT location, date, new_cases, lag_new_cases, rel_diff,
(CASE WHEN rel_diff>0 THEN 'Increase'
     WHEN rel_diff<0 THEN 'Decrease'
     WHEN rel_diff=0 THEN 'No change'
     ELSE NULL END) trend
FROM cte
ORDER BY location, date; 
```
###### Results
