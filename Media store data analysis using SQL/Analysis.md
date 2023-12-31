# Data Analysis:

In this project I analyze data about digital media store using SQL quaries. This dataset has 11 tables about customers, employees, orders, artists, music genre, etc.
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
FROM `chinook.invoice`
GROUP BY BillingCity
HAVING SUM(Total) = 
 (
  SELECT MAX(sum_total) 
  FROM
  (
    SELECT BillingCity, SUM(Total) AS sum_total
    FROM `chinook.invoice`
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
  FROM `chinook.customer` c
  LEFT JOIN
  `chinook.invoice` i 
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
#### Top-1 client by amount spent
| Client        | Total spent           | 
| ------------- |:---------------------:|
| Helena Holý   |          49.62        |
## Who is the singer who has earned the most and who is the user that has spent the most on this singer?
> ###### Query
```
WITH tbl_best_selling_artist AS(
SELECT artist.ArtistId AS artist_id,artist.Name AS artist_name,
SUM(invoiceline.UnitPrice*invoiceline.Quantity) AS total_sales
FROM `chinook.invoiceline` invoiceline
JOIN `chinook.track` track ON track.TrackId = invoiceline.TrackId
JOIN `chinook.album` album ON album.AlbumId = track.AlbumId
JOIN `chinook.artist` artist ON artist.ArtistId = album.ArtistId
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1
)
SELECT bsa.artist_name,SUM(il.UnitPrice*il.Quantity) AS amount_spent,c.CustomerId,c.FirstName,c.LastName
FROM `chinook.invoice` i
JOIN `chinook.customer` c ON c.CustomerId = i.CustomerId
JOIN `chinook.invoiceline` il ON il.InvoiceId = i.InvoiceId
JOIN `chinook.track` t ON t.TrackId = il.TrackId
JOIN `chinook.album` alb ON alb.AlbumId = t.AlbumId
JOIN tbl_best_selling_artist bsa ON bsa.artist_id = alb.ArtistId
GROUP BY 1,3,4,5
ORDER BY 2 DESC;
```
###### Results
#### Top-1 singer by earnings and the user who has spent the most on the singer
| Name of the singer   | Name of the user      |         Amount spent      |
| ---------------------|:---------------------:|:-------------------------:|
| Iron Maiden          |     Mark Taylor       |              17.82        |
## Which genre is the most popular in each country? 
The most popular genres are defined as the ones that were bought the most frequently.
> ###### Query
```
WITH
country_data AS(
SELECT  il.Quantity, g.Name AS genre_name, g.GenreId, t.TrackId, i.BillingCountry
  FROM `chinook.genre` g
  INNER JOIN `chinook.track` t
  ON g.GenreId=t.GenreId
  INNER JOIN `chinook.invoiceline` il
  ON t.TrackId=il.TrackId
  INNER JOIN `chinook.invoice` i
  ON il.InvoiceId=i.InvoiceId),
sum_genre_country AS (
  SELECT BillingCountry, genre_name, SUM(Quantity) AS sum_total
  FROM country_data
  GROUP BY BillingCountry, genre_name),
rank_sum AS (
SELECT BillingCountry, genre_name, sum_total,
RANK() OVER (PARTITION BY BillingCountry ORDER BY sum_total DESC) as RN
FROM sum_genre_country)
SELECT BillingCountry, genre_name, sum_total
FROM rank_sum 
WHERE RN =1
ORDER BY sum_total DESC
LIMIT 5;
```
###### Results
#### 5 countries with the greatest number of purchases and the most popular genres in these countries 
| Country       |        Genre          | The number of times purchased|  
| ------------- |:---------------------:|:----------------------------:|
| USA           |         Rock          |             157              |
| Canada        |         Rock          |             107              |
| Brazil        |         Rock          |             81               |  
| France        |         Rock          |             65               |  
| Germany       |         Rock          |             62               | 

## Which client has spent the most in each country? How much have these clients spent?
> ###### Query
```
WITH
sum_by_customer AS(
  SELECT
    CustomerId,
    SUM(Total) AS sum_total_by_customer
  FROM
    `chinook.invoice`
  GROUP BY
  CustomerId),
customer_country AS(
  SELECT sc.CustomerId, sc.sum_total_by_customer, c.FirstName, c.LastName, c.Country
  FROM `chinook.customer` c
  LEFT JOIN sum_by_customer sc
  ON c.CustomerId=sc.CustomerId),
rank_in_country AS (
  SELECT Country, FirstName, LastName, sum_total_by_customer,
  RANK() OVER (PARTITION BY Country ORDER BY sum_total_by_customer DESC) as RN
  FROM customer_country)
SELECT Country, CONCAT(FirstName,' ',LastName) AS customer_name, sum_total_by_customer
FROM rank_in_country
WHERE RN =1
ORDER BY sum_total_by_customer
LIMIT 5;
```
###### Results
#### 5 countries with the greatest amount spent by clients

| Country       |     Customer name     |       Amount spent           |  
| ------------- |:---------------------:|:----------------------------:|
| Belgium       |    Daan Peeters       |           37.62              |
| Spain         |    Enrique Muñoz      |           37.62              |
| Poland        |   Stanisław Wójcik    |           37.62              |  
| Argentina     |    Diego Gutiérrez    |           37.62              |  
| Australia     |      Mark Taylor      |           37.62              |

## What are the top 10 albums by sales? How much did they earn?
> ###### Query
```
WITH
total_by_trackid AS(
  SELECT TrackId, SUM(UnitPrice*Quantity) AS Total_earned
  FROM `chinook.invoiceline`
  GROUP BY TrackId
), 
album_data AS(
SELECT Title AS album_title, t.TrackId, Total_earned
FROM
`chinook.album` alb
INNER JOIN
`chinook.track` t 
ON
  alb.AlbumId=t.AlbumId
INNER JOIN
total_by_trackid tt 
ON
  t.TrackId=tt.TrackId
),
sum_of_total AS(
  SELECT album_title, SUM(Total_earned) AS sum_by_album
  FROM album_data
  GROUP BY album_title)
SELECT album_title, sum_by_album
FROM sum_of_total
ORDER BY sum_by_album DESC
LIMIT 10;
```
###### Results
<a href="top10_albums.png"><img src="images/top10_albums.png" style="min-width: 300px"></a>
## Top 10 US states by sales
> ###### Query
```
WITH us_data AS(
  SELECT c.Country, c.State, i.Total
  FROM `chinook.customer` c
  INNER JOIN
  `chinook.invoice` i 
  ON
  c.CustomerId=i.CustomerId
  WHERE c.Country='USA')
SELECT State, ROUND(SUM(Total),2) AS sum_by_state
FROM us_data
GROUP BY State
ORDER BY sum_by_state DESC
LIMIT 10;
```
###### Results
<a href="top10_states.png"><img src="images/top10_states.png" style="min-width: 300px"></a>
## Share of each media type in sales
> ###### Query
```
WITH
total_by_trackid AS(
  SELECT TrackId, SUM(UnitPrice*Quantity) AS Total_earned
  FROM `da-nfactorial.chinook.invoiceline`
  GROUP BY TrackId
), 
media_data AS(
SELECT md.MediaTypeId, md.Name AS media_name, Total_earned, t.TrackId
FROM
`da-nfactorial.chinook.mediatype` md
INNER JOIN
`da-nfactorial.chinook.track` t 
ON
  md.MediaTypeId=t.MediaTypeId
INNER JOIN
total_by_trackid tt
ON
  t.TrackId=tt.TrackId
),
total_sum AS ( 
  SELECT SUM(Total_earned) AS final_sum
  FROM media_data),
sum_of_total_by_media AS(
  SELECT media_name, SUM(Total_earned) AS sum_by_media
  FROM media_data
  GROUP BY media_name)
SELECT media_name, (sum_by_media/(SELECT final_sum FROM total_sum))*100 AS media_share_in_percent
FROM sum_of_total_by_media
ORDER BY media_share_in_percent DESC;
```
###### Results
<a href="share of each media type.png"><img src="images/share of each media type.png" style="min-width: 300px"></a>
