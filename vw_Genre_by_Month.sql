/********************************************************************************************
View:       vw_Genre_by_Month_and_Prev
Author:     Yevgeniy Ledvin
Purpose:    Provides month‑over‑month sales totals by genre, including current month sales
            and the previous month's sales for comparison.

Description:
    This view aggregates sales at the genre level using order, order item, book, and 
    translation data. It computes total sales per genre per month and then performs a 
    self‑join to align each month with its corresponding previous month. This enables 
    reporting on month‑over‑month performance trends.

Logic Overview:
    1. SalesCTE:
         • Aggregates total sales (Quantity × UnitPrice) by:
               – Genre
               – Year
               – Month
         • Joins Order → OrderItems → BookTranslation → Book → Genre.

    2. CurrentMonth CTE:
         • Exposes the aggregated results for the current month.

    3. PreviousMonth CTE:
         • Provides the same aggregated results for use in a self‑join.

    4. Final SELECT:
         • Joins CurrentMonth to PreviousMonth on:
               – Same GenreID
               – Previous month logic:
                     a) Same year, month - 1
                     b) January rollover (month = 1 → previous December of prior year)
         • Returns:
               – GenreName
               – SalesYear
               – SalesMonth
               – CurrentMonth (formatted as “MonthName Year”)
               – CurrentMonthSales
               – PreviousMonthSales
         • Ordered by Genre, Year, Month.

Returned Columns:
    • GenreName              – Name of the genre.
    • SalesYear              – Year of the sales period.
    • SalesMonth             – Month of the sales period.
    • CurrentMonth           – Formatted month name and year.
    • CurrentMonthSales      – Total sales for the month.
    • PreviousMonthSales     – Total sales for the previous month.

Notes:
    • Uses CTEs for clarity and maintainability.
    • TOP 10000000 is used to ensure compatibility with ORDER BY inside a view.
    • Ideal for dashboards, BI tools, and trend analysis.
********************************************************************************************/



USE [BookStore]
GO

/****** Object:  View [dbo].[vw_Genre_by_Month_and_Prev]    Script Date: 6/4/2026 5:15:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER VIEW [dbo].[vw_Genre_by_Month_and_Prev]
AS
WITH SalesCTE AS (
    SELECT        g.Name AS GenreName, YEAR(o.OrderDate) AS SalesYear, MONTH(o.OrderDate) AS SalesMonth, SUM(oi.Quantity * oi.UnitPrice) AS TotalSales, b.GenreID
FROM            dbo.[Order] AS o INNER JOIN
                         dbo.OrderItems oi ON o.OrderID = oi.OrderID INNER JOIN
                         dbo.BookTranslation bt ON oi.ISBN = bt.ISBN INNER JOIN
                         dbo.Book b ON bt.BookID = b.BookID INNER JOIN
                         dbo.Genre g ON b.GenreID = g.GenreID
GROUP BY g.Name, YEAR(o.OrderDate), MONTH(o.OrderDate), b.GenreID
),
CurrentMonth AS (
    SELECT 
        GenreID,
        GenreName,
        SalesYear,
        SalesMonth,
        TotalSales
    FROM SalesCTE
),
PreviousMonth AS (
    SELECT 
        GenreID,
        SalesYear,
        SalesMonth,
        TotalSales
    FROM SalesCTE
)
SELECT TOP 10000000
    c.GenreName,
    c.SalesYear,
    c.SalesMonth,
    CONCAT((DATENAME(MONTH,c.SalesMonth)), ' ' ,c.SalesYear) AS CurrentMonth,
    c.TotalSales AS CurrentMonthSales,
    p.TotalSales AS PreviousMonthSales
FROM CurrentMonth c
LEFT JOIN PreviousMonth p
    ON p.GenreID = c.GenreID
    AND (
            (p.SalesYear = c.SalesYear AND p.SalesMonth = c.SalesMonth - 1)
         OR (c.SalesMonth = 1 AND p.SalesYear = c.SalesYear - 1 AND p.SalesMonth = 12)
       )

ORDER BY c.GenreName, c.SalesYear, c.SalesMonth
       
GO


