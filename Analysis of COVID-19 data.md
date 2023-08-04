# Data Analysis:

In this project I analyze data about COVID-19 from Our World in Data website using SQL quaries. 
This dataset contains 6 tables about new cases of COVID-19, demography in countries, 
new admissions to hospitals, locations included in the dataset, tests conducted, vaccinations. 
All tables are connected through variables: *iso_code* and *date*.
##### Cleaning the data
First, I clean the data: checking for duplicates in the data, for example, in Regions table.  
> ###### Query
```
SELECT r.iso_code, r.continent, r.location,
COUNT(*) AS checking_dup
FROM `covid19.regions` r
GROUP BY r.iso_code, r.continent, r.location
HAVING checking_dup > 1; 
```
Valid *iso_code* consists of three characters. So I check whether there are observations with *iso_code* that contain more than three characters.
> ###### Query
```
SELECT c.iso_code
FROM `covid19.cases` c
WHERE c.iso_code NOT LIKE '___'
GROUP BY c.iso_code; 
```
##### Results
There are observations with *iso_code*: "OWID_KOS" which is *iso_code* for the Republic of Kosovo. For other observations *iso_code* consists of three characters.
Next, I examine countries' names and remove text in brackets that is not needed for this analysis.
> ###### Query
```
SELECT r.location,
CONCAT(
LEFT(r.location,STRPOS(r.location, '(')-1),' ',
RIGHT(r.location,LENGTH(r.location)-STRPOS(r.location, ')')))
FROM `covid19.regions` r
WHERE r.location LIKE '%(%)%'
GROUP BY r.location; 
```
I also check whether data types are appropriate. In Hospital table such variables as *weekly_icu_admissions*, *hosp_patients*, *weekly_hosp_admissions* are STRING type, while they are numbers and should be FLOAT type. So I change the data type of these variables to FLOAT.
> ###### Query
```
SELECT *, 
CAST(h.weekly_icu_admissions AS FLOAT64) AS weekly_icu_admissions_new,
CAST(h.hosp_patients AS FLOAT64) AS hosp_patients_new,
CAST(h.weekly_hosp_admissions AS FLOAT64) AS weekly_hosp_admissions_new
FROM `covid19.hospital` h;
```
### Analysis
##### Question 1: In which country probability of death of an infected person was the highest?
> ###### Query
```
WITH prob AS(
SELECT location, c.date, c.total_deaths, c.total_cases, ROUND((c.total_deaths/c.total_cases)*100,2) AS probability
FROM `covid19.cases` c
INNER JOIN `covid19.regions` r
ON c.iso_code=r.iso_code)

SELECT location, date, probability
FROM prob
WHERE probability=(SELECT MAX(probability) FROM prob)
ORDER BY date; 
```
###### Results
| Country       |    Date   |  Probability  |
| ------------- |:---------:|--------------:|
| North Korea   |2022-05-14 |      600.0    | 
| North Korea   |2022-05-15 |      600.0    |
##### Question 2: What was the percentage of infected people and the percentage of people dying from COVID-19 in each country?
> ###### Query
```
WITH cte AS(
SELECT r.location, c.iso_code, 
SUM(c.new_cases) AS all_cases, SUM(c.new_deaths) AS all_deaths
FROM `covid19.cases` c
INNER JOIN `covid19.regions` r
ON c.iso_code=r.iso_code
GROUP BY c.iso_code, r.location)

SELECT location, all_cases, all_deaths, d.population,
ROUND((all_cases/d.population)*100,2) AS prob_ill,
ROUND((all_deaths/d.population)*100,2) AS prob_death
FROM cte cc
INNER JOIN `covid19.demography` d
ON cc.iso_code=d.iso_code 
ORDER BY prob_ill DESC; 
```
<a href="question 2 results.png"><img src="images for COVID-19 analysis/question 2 results.png" style="min-width: 300px"></a>
##### Question 3: What was the percentage of infected people and the percentage of people dying from COVID-19 in the world?
> ###### Query
```
WITH cte AS(
SELECT  c.iso_code,
SUM(c.new_cases) AS all_cases, SUM(c.new_deaths) AS all_deaths
FROM `covid19.cases` c
INNER JOIN `covid19.regions` r
ON c.iso_code=r.iso_code
GROUP BY c.iso_code)

SELECT SUM(all_cases) AS total_cases, SUM(all_deaths) AS total_deaths, 
SUM(d.population) AS total_population,
ROUND((SUM(all_cases)/SUM(d.population))*100,2) AS prob_ill,
ROUND((SUM(all_deaths)/SUM(d.population))*100,2) AS prob_death
FROM cte cc
INNER JOIN `covid19.demography` d
ON cc.iso_code=d.iso_code; 
```
###### Results
| Total cases   | Total deaths | Total population |Probability of getting ill, %|Probability of mortality, %|
| ------------- |:------------:|-----------------:|----------------------------:|--------------------------:|
|  583 081 360  |   6 426 391  |  7 898 275 810   |            7.38             |             0.08          |

##### Question 4: Which countries have coped well with treating COVID-19?
In this case, it is considered that a country have coped well with COVID-19 treatment if the most recent observation for the number of patients in the intensive care unit is smaller than the earliest observation for the number of patients in the intensive care unit.
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
FROM `covid19.hospital` h
INNER JOIN `covid19.regions` r
ON h.iso_code=r.iso_code)
WHERE row_num=1
ORDER BY diff;
```
<a href="question 4 results.png"><img src="images for COVID-19 analysis/question 4 results.png" style="min-width: 300px"></a>

##### Question 5: How did the number of new cases change on a daily basis in each country?
I estimate daily percentage change in new cases and add a new variable trend which shows whether percentage change increased/decreased/didn't change.
> ###### Query
```
WITH cte AS 
(SELECT r.location, c.date, c.new_cases, 
LAG(c.new_cases) OVER (PARTITION BY r.location ORDER BY c.date ASC) AS lag_new_cases,
100*(c.new_cases-LAG(c.new_cases) OVER (PARTITION BY r.location ORDER BY c.date))/NULLIF(LAG(c.new_cases) OVER (PARTITION BY c.iso_code ORDER BY c.date),0) AS rel_diff
FROM `covid19.cases` c
INNER JOIN `covid19.regions` r
ON c.iso_code=r.iso_code )

SELECT location, date, new_cases, lag_new_cases, rel_diff,
(CASE WHEN rel_diff>0 THEN 'Increase'
     WHEN rel_diff<0 THEN 'Decrease'
     WHEN rel_diff=0 THEN 'No change'
     ELSE NULL END) trend
FROM cte
ORDER BY location, date; 
```
<a href="question 5 results.png"><img src="images for COVID-19 analysis/question 5 results.png" style="min-width: 300px"></a>

##### Question 6: Which countries in the dataset had the highest mortality rate during COVID-19?
> ###### Query
```
WITH rank_country AS(
  SELECT c.iso_code, c.date, c.new_deaths, d.population,
  RANK () OVER (ORDER BY (c.new_deaths/d.population)*100 DESC) AS rn
  FROM `covid19.cases` c
  LEFT JOIN `da-nfactorial.covid19.demography` d
  ON c.iso_code=d.iso_code)

SELECT r.location, rc.date, new_deaths, population, 
(new_deaths/population)*100 AS mort, rn
FROM rank_country rc
LEFT JOIN `covid19.regions` r
ON rc.iso_code=r.iso_code
WHERE rn <=25
ORDER BY rn; 
```
<a href="question 6 results.png"><img src="images for COVID-19 analysis/question 6 results.png" style="min-width: 300px"></a>

##### Question 7: Forecasting the number of new cases for the next five days.      
I estimate the growth factor of new cases for day N as the number of new cases for day N divided by the number of new cases for day (N-1).
For more precise estimation I use average value of the growth factor for the last 10 days.
For forecasting new cases in N days I use the following formula:
_New cases in N days=(new cases today)*(the growth factor)^N_
> ###### Query
```
WITH nfact AS 
(SELECT r.location, c.date, IFNULL(c.new_cases,0) AS new_cases,
LAG(IFNULL(c.new_cases,0)) OVER (PARTITION BY c.iso_code ORDER BY c.date ASC) AS lag_new_cases,
IFNULL(c.new_cases,0)/NULLIF(LAG(c.new_cases) OVER (PARTITION BY c.iso_code ORDER BY c.date ASC),0) AS Nfact,
FROM `covid19.cases` c
LEFT JOIN `covid19.demography` d
ON c.iso_code=d.iso_code 
LEFT JOIN `covid19.regions` r
ON d.iso_code=r.iso_code
WHERE r.location='Kazakhstan' AND c.date<='2022-07-30')
SELECT location, nf.date, new_cases, lag_new_cases, Nfact,
AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS Nfact_AVG,
new_cases*POWER(AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW),5) AS forecast_for_5days
FROM nfact nf
ORDER BY nf.date DESC; 
```
<a href="question 7 results.png"><img src="images for COVID-19 analysis/question 7 results.png" style="min-width: 300px"></a>

##### Question 8: Which countries had the highest increase in the vaccination rate for COVID-19?
> ###### Query
```
WITH cte AS 
(SELECT r.location, v.date, v.new_vaccinations, 
LAG(v.new_vaccinations) OVER (PARTITION BY r.location ORDER BY v.date ASC) AS lag_new_vaccinations,
FROM `covid19.vaccinations` v
INNER JOIN `da-nfactorial.covid19.regions` r
ON v.iso_code=r.iso_code )

SELECT location, ROUND(((new_vaccinations-lag_new_vaccinations)/NULLIF(lag_new_vaccinations,0)),2) AS rel_diff
FROM cte
ORDER BY rel_diff DESC
LIMIT 10; 
```
###### Results
<a href="relative increase in the number of vaccinated people.png"><img src="images for COVID-19 analysis/relative increase in the number of vaccinated people.png" style="min-width: 300px"></a>
##### Question 9: Next, I investigate whether there is relationship between population density and share of infected people in countries
> ###### Query
```
WITH cte AS(
SELECT r.location, c.iso_code, 
SUM(c.new_cases) AS all_cases
FROM `covid19.cases` c
INNER JOIN `covid19.regions` r
ON c.iso_code=r.iso_code
GROUP BY c.iso_code, r.location)
SELECT location, 
ROUND((all_cases/d.population)*100,2) AS prob_ill, d. population_density
FROM cte cc
INNER JOIN `covid19.demography` d
ON cc.iso_code=d.iso_code 
ORDER BY prob_ill DESC;  
```
###### Results
As it can be seen from the graph, there is no obvious relationship between population density and the share of infected people in countries.
<a href="relationship between population density and share of infected people in countries.png"><img src="images for COVID-19 analysis/relationship between population density and share of infected people in countries.png" style="min-width: 300px"></a>

##### Question 10: Next, I estimate how many new COVID-19 tests the United Kingdom would need to conduct in the next five days based on tests conducted in the previous days.
Forecasting method is the same as the one used in question #7.
> ###### Query
```
WITH nfact AS 
(SELECT t.iso_code, t.date, t.new_tests, 
LAG(t.new_tests) OVER (PARTITION BY t.iso_code ORDER BY t.date ASC) AS lag_new_tests,
t.new_tests/NULLIF(LAG(t.new_tests) OVER (PARTITION BY t.iso_code ORDER BY t.date ASC),0) AS Nfact,
FROM `covid19.tests` t)
SELECT location, nf.date, 
AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS Nfact_AVG,  new_tests,
new_tests*POWER(AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW),1) AS forecast_for_1days,
new_tests*POWER(AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW),2) AS forecast_for_2days,
new_tests*POWER(AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW),3) AS forecast_for_3days,
new_tests*POWER(AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW),4) AS forecast_for_4days,
new_tests*POWER(AVG(Nfact) OVER(ORDER BY nf.date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW),5) AS forecast_for_5days
FROM nfact nf
LEFT JOIN `covid19.regions` r
ON nf.iso_code=r.iso_code
WHERE UPPER(location)='UNITED KINGDOM'
ORDER BY nf.date DESC
LIMIT 1;
```
###### Results
<a href="forecast of new covid tests for the United Kingdom.png"><img src="images for COVID-19 analysis/forecast of new covid tests for the United Kingdom.png" style="min-width: 300px"></a>
