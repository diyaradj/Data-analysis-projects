SELECT Email, FirstName, LastName, g.Name
FROM
  `da-nfactorial.chinook.customer` c
LEFT JOIN
  `da-nfactorial.chinook.invoice` i 
ON
  c.CustomerId=i.CustomerId
LEFT JOIN
  `da-nfactorial.chinook.invoiceline` il 
ON
  i.InvoiceId=il.InvoiceId
LEFT JOIN
  `da-nfactorial.chinook.track` t 
ON
  il.TrackId=t.TrackId
LEFT JOIN
  `da-nfactorial.chinook.genre` g 
ON
  t.GenreId=g.GenreId
WHERE g.Name='Rock'
ORDER BY Email;

