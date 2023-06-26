# Data Analysis:

In this project I analyze Chinook dataset. It contains data about digital media store. This dataset has 11 tables about customers, employees, orders, artists, music genre, etc.
## Which countries have the greatest number of invoices?

> ###### Query
```
SELECT BillingCountry, COUNT(DISTINCT InvoiceId) AS Invoices_count
FROM `chinook.invoice`
GROUP BY BillingCountry
ORDER BY Invoices_count DESC
LIMIT 5;
```
###### Results
#### Top 5 Countries with the greatest number of invoices

| Country       | Quantity of invoices  | 
| ------------- |:---------------------:|
| USA           |          91           | 
| Canada        |          56           |  
|  Brazil       |          35           |  
| France        |          35           |  
| Germany       |          28           |  

## In which city did the media store earn the most?
> ###### Query
```
SELECT BillingCity, SUM(Total) AS sum_total
FROM `da-nfactorial.chinook.invoice`
GROUP BY BillingCity
HAVING SUM(Total) = 
 (
  SELECT MAX(sum_total) 
  FROM
  (
    SELECT BillingCity, SUM(Total) AS sum_total
    FROM `da-nfactorial.chinook.invoice`
    GROUP BY BillingCity));
```
###### Results
#### Top 1 city by earnings
| City          | Earnings              | 
| ------------- |:---------------------:|
| Prague        |          90.24        |

## Who is the client who has spent the most?
> ###### Query
```
WITH
customer_invoice_data AS (
  SELECT FirstName, LastName, Total
  FROM `da-nfactorial.chinook.customer` c
  LEFT JOIN
  `da-nfactorial.chinook.invoice` i 
ON
  c.CustomerId=i.CustomerId
)
SELECT CONCAT(FirstName,' ', LastName) AS name, SUM(Total) AS sum_total
FROM 
  customer_invoice_data
GROUP BY name
HAVING SUM(Total) = 
 (
  SELECT MAX(sum_total) 
  FROM
   (
     SELECT CONCAT(FirstName,' ', LastName) AS name, SUM(Total) AS sum_total
     FROM customer_invoice_data
     GROUP BY name));
```
###### Results
#### Top 1 client by amount spent
| Client        | Total spent           | 
| ------------- |:---------------------:|
| Helena Holý   |          49.62        |

