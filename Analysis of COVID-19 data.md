# Data Analysis:

In this project I analyze data about COVID-19 from Our World in Data website using SQL quaries. 
This dataset contains 6 tables about new cases of COVID-19, demography in countries, 
new admissions to hospitals, locations included in the dataset, tests conducted, vaccinations. 
All tables are connected using variables: iso_code and date.
### First, I clean the data: checking for duplicates in the data, for example, in Regions table.  
> ###### Query
```
SELECT r.iso_code, r.continent, r.location,
COUNT(*) AS checking_dup
FROM `da-nfactorial.covid19.regions` r
GROUP BY r.iso_code, r.continent, r.location
HAVING checking_dup > 1; 
```
### Next, I check whether there are observations with iso_code that contain more than three characters as it is supposed to.
> ###### Query
```
SELECT c.iso_code
FROM `da-nfactorial.covid19.cases` c
WHERE c.iso_code NOT LIKE '___'
GROUP BY c.iso_code; 
```
### Results
There are observations with code: "OWID_KOS".
### Next, I remove text in brackets in countries' name.
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
### I check whether data types are correct. In hospital table, variables: types weekly_icu_admissions, hosp_patients, weekly_hosp_admissions are STRING, while they are numbers and should be of type FLOAT. So I change the data type of these variables to FLOAT.
> ###### Query
```
SELECT *, 
CAST(h.weekly_icu_admissions AS FLOAT64) AS weekly_icu_admissions_new,
CAST(h.hosp_patients AS FLOAT64) AS hosp_patients_new,
CAST(h.weekly_hosp_admissions AS FLOAT64) AS weekly_hosp_admissions_new
FROM `da-nfactorial.covid19.hospital` h;
```

