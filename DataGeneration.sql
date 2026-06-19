/********************************************************************************************
Procedure: usp_GenerateSampleData
Author:    Yevgeniy Ledvin
Purpose:   Populates the BookStore database with randomized sample data for development,
           testing, demos, and performance evaluation.

Description:
    This stored procedure generates a complete set of sample data across all major tables
    in the BookStore schema. It inserts genres, books, translations, customers, reviews,
    price schedules, orders, order items, and invoices. Randomization is used extensively
    to simulate realistic and varied data patterns.

Data Generation Stages:

1. Genre Creation
    • Inserts 5 predefined genres into dbo.Genre.

2. Book Creation
    • Inserts 20 books.
    • Each book is assigned a random GenreID using ORDER BY NEWID().

3. Book Translation Creation
    • For each iteration, selects a random BookID.
    • Inserts 3 translations per book (EN, RU, FR).
    • Generates:
         – Random ISBN values
         – Random publish dates (up to ~2000 days in the past)
         – Random default prices (10–40 range)
         – Language‑specific titles and descriptions

4. Customer Creation
    • Inserts 10 customers with synthetic names, emails, addresses, and phone numbers.

5. Review Creation
    • Inserts 50 reviews.
    • Each review:
         – Random BookID
         – Random CustomerID
         – Random rating (1–5)
         – Random review date (within past year)

6. Price Schedule Creation
    • Inserts 20 promotional price rules.
    • Each rule:
         – Applies to a random ISBN
         – Sets a discounted price (DefaultPrice – 5)
         – Uses a future date range (StartDate +10 days, EndDate +40 days)

7. Order, OrderItems, and Invoice Creation
    • Creates 20 orders.
    • For each order:
         – Random CustomerID
         – Random OrderDate (within past ~200 days)
         – Inserts 1–3 random order items
         – Calculates TotalAmount from OrderItems
         – Inserts a matching Invoice with the computed total

Behavior:
    • Uses multiple WHILE loops to generate controlled volumes of data.
    • Uses NEWID(), CHECKSUM(), RAND(), and ABS() for randomization.
    • Ensures referential integrity by selecting valid foreign keys at each step.
    • Uses SCOPE_IDENTITY() to capture newly created OrderIDs.

Error Handling:
    • No TRY/CATCH block is used; errors will bubble naturally.
    • Consider wrapping the entire procedure in a transaction for atomicity.

Notes:
    • Designed for non‑production environments only.
    • Data volume can be increased by adjusting loop counters.
    • Randomization ensures each execution produces unique datasets.
********************************************************************************************/



CREATE OR ALTER PROCEDURE usp_GenerateSampleData
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Genre (Name, Description)
    VALUES ('Fiction', 'Fictional works'),
           ('Science', 'Scientific literature'),
           ('History', 'Historical books'),
           ('Fantasy', 'Fantasy novels'),
           ('Technology', 'Tech and programming books');

   
    DECLARE @i INT = 1;

    WHILE @i <= 20
    BEGIN
        INSERT INTO Book ( GenreID)
        VALUES (
            
            (SELECT TOP 1 GenreID FROM Genre ORDER BY NEWID())
        );

        SET @i += 1;
    END;

   
    declare @bookidtr int
    

set @i   = 1;

    WHILE @i <= 2
    Begin
    SELECT @bookidtr = BookID
FROM (
    SELECT TOP 1 BookID
    FROM Book
    
    ORDER BY NEWID()
) AS x

    INSERT INTO BookTranslation (BookID,ISBN, LanguageCode, Title, Description, PublishDate,
    DefaultPrice)
    SELECT @bookidtr, CONCAT('978-0000-',round(rand()*1000,0),'-', @i), 'EN',
           CONCAT('Book Title ', @bookidtr),
           CONCAT('English description for book ', @bookidtr)
           ,
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 2000, GETDATE()),
            (10 + (ABS(CHECKSUM(NEWID())) % 30))
    ;
    SET @i+=1
    INSERT INTO BookTranslation (BookID,ISBN, LanguageCode, Title, Description,PublishDate,
    DefaultPrice)
    SELECT @bookidtr, CONCAT('978-0000-',round(rand()*1000,0),'-', @i),'RU',
           CONCAT(N'Название книги ', @bookidtr),
           CONCAT(N'Описание книги на русском ', @bookidtr),
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 2000, GETDATE()),
            (10 + (ABS(CHECKSUM(NEWID())) % 30))
    ;

    SET @i+=1

    INSERT INTO BookTranslation (BookID, ISBN,LanguageCode, Title, Description,PublishDate ,
    DefaultPrice)
    SELECT @bookidtr,CONCAT('978-0000-',round(rand()*1000,0),'-', @i), 'FR',
           CONCAT('Titre Livre ', @bookidtr),
           CONCAT('Description française pour livre ', @bookidtr),
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 2000, GETDATE()),
            (10 + (ABS(CHECKSUM(NEWID())) % 30))
    ;
    SET @i+=1
    END;
   

    SET @i = 1;
    WHILE @i <= 10
    BEGIN
        INSERT INTO Customer (Name, Email, Address, Phone)
        VALUES (
            CONCAT('Customer ', @i),
            CONCAT('customer', @i, '@mail.com'),
            CONCAT('123 Street #', @i),
            CONCAT('555-000', @i)
        );

        SET @i += 1;
    END;

    

    INSERT INTO Review (BookID, CustomerID, Rating, Comment, ReviewDate)
    SELECT TOP 50
           (SELECT TOP 1 BookID FROM Book ORDER BY NEWID()),
           (SELECT TOP 1 CustomerID FROM Customer ORDER BY NEWID()),
           (ABS(CHECKSUM(NEWID())) % 5) + 1,
           'Sample review text',
           DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE())
    FROM sys.objects;

   
    

    INSERT INTO PriceSchedule (ISBN, StartDate, EndDate, Price)
    SELECT TOP 20
           ISBN,
           DATEADD(DAY, 10, GETDATE()),
           DATEADD(DAY, 40, GETDATE()),
           DefaultPrice - 5
    FROM BookTranslation
    ORDER BY NEWID();

    

    SET @i = 1;
    WHILE @i <= 20
    BEGIN
        DECLARE @CustomerID INT =
            (SELECT TOP 1 CustomerID FROM Customer ORDER BY NEWID());

        INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount)
        VALUES (@CustomerID, DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 200, GETDATE()), 0);

        DECLARE @OrderID INT = SCOPE_IDENTITY();

        

        DECLARE @j INT = 1;
        WHILE @j <= (1 + ABS(CHECKSUM(NEWID())) % 3)
        BEGIN
            DECLARE @ISBN NVARCHAR(20) =
                (SELECT TOP 1 ISBN FROM BookTranslation ORDER BY NEWID());

            DECLARE @Price DECIMAL(10,2) =
                (SELECT DefaultPrice FROM BookTranslation WHERE ISBN = @ISBN);

            INSERT INTO OrderItems (OrderID, ISBN, Quantity, UnitPrice)
            VALUES (@OrderID, @ISBN, 1, @Price);

            SET @j += 1;
        END;

        
        UPDATE o
        SET TotalAmount = (
            SELECT SUM(Quantity * UnitPrice)
            FROM OrderItems
            WHERE OrderID = o.OrderID
        )
        FROM [Order] o
        WHERE o.OrderID = @OrderID;

        
        INSERT INTO Invoice (OrderID, CustomerID, InvoiceDate, BillingAddress, TotalAmount)
        VALUES (
            @OrderID,
            @CustomerID,
            GETDATE(),
            'Billing Address',
            (SELECT TotalAmount FROM [Order] WHERE OrderID = @OrderID)
        );

        SET @i += 1;
    END
    END

GO

--exec usp_GenerateSampleData



