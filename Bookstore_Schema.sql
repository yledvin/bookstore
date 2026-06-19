/********************************************************************************************
Database Schema: Online Bookstore
Author:         Yevgeniy
Purpose:        Defines the core transactional and reference tables for the bookstore system,
                including books, translations, pricing, customers, orders, reviews, and invoices.

Overview:
    This schema supports:
        • Book catalog and genre classification
        • Multilingual book metadata (via BookTranslation)
        • Customer management
        • Reviews and ratings
        • Dynamic pricing schedules
        • Orders, order items, and invoicing

----------------------------------------------------------------------------------------------
TABLE: Genre
----------------------------------------------------------------------------------------------
Purpose:
    Stores book categories (e.g., Fiction, History, Sci‑Fi).

Columns:
    • GenreID (PK, identity starting at 100)
    • Name – Genre name
    • Description – Optional description

Notes:
    • Referenced by Book.

----------------------------------------------------------------------------------------------
TABLE: Book
----------------------------------------------------------------------------------------------
Purpose:
    Represents a book entity without language‑specific metadata.

Columns:
    • BookID (PK, identity starting at 1000)
    • GenreID (FK → Genre.GenreID)

Notes:
    • All titles, descriptions, ISBNs, and prices are stored in BookTranslation.

----------------------------------------------------------------------------------------------
TABLE: BookTranslation
----------------------------------------------------------------------------------------------
Purpose:
    Stores language‑specific book metadata and pricing defaults.

Columns:
    • BookID (FK → Book.BookID)
    • ISBN (PK, unique identifier for translation)
    • LanguageCode (2‑char ISO code)
    • Title
    • Description
    • PublishDate
    • DefaultPrice

Indexes:
    • IDX_BookTranslation_BookID – speeds up lookups by BookID.

Notes:
    • Supports multiple translations per book.
    • ISBN is the primary key.

----------------------------------------------------------------------------------------------
TABLE: Customer
----------------------------------------------------------------------------------------------
Purpose:
    Stores customer contact and identity information.

Columns:
    • CustomerID (PK, identity starting at 1000)
    • Name
    • Email (unique)
    • Address
    • Phone

Notes:
    • Referenced by Order, Review, Invoice.

----------------------------------------------------------------------------------------------
TABLE: Review
----------------------------------------------------------------------------------------------
Purpose:
    Stores customer reviews and ratings for books.

Columns:
    • ReviewID (PK)
    • BookID (FK → Book.BookID)
    • CustomerID (FK → Customer.CustomerID)
    • Rating (1–5)
    • Comment
    • ReviewDate (default GETDATE)

Indexes:
    • IDX_Review_BookID – improves book review lookups.
    • IDX_Review_CustomerID – improves customer review lookups.

----------------------------------------------------------------------------------------------
TABLE: PriceSchedule
----------------------------------------------------------------------------------------------
Purpose:
    Defines time‑based pricing overrides for specific ISBNs.

Columns:
    • PriceScheduleID (PK)
    • ISBN (FK → BookTranslation.ISBN)
    • StartDate
    • EndDate
    • Price

Indexes:
    • IDX_PriceSchedule_BookID – improves price lookup by ISBN.

Notes:
    • Supports promotional pricing and historical price tracking.

----------------------------------------------------------------------------------------------
TABLE: Order
----------------------------------------------------------------------------------------------
Purpose:
    Represents a customer order.

Columns:
    • OrderID (PK, identity starting at 10000)
    • CustomerID (FK → Customer.CustomerID)
    • OrderDate (default GETDATE)
    • TotalAmount (default 0)

Indexes:
    • IDX_Order_CustomerID – improves customer order lookups.

----------------------------------------------------------------------------------------------
TABLE: OrderItems
----------------------------------------------------------------------------------------------
Purpose:
    Stores individual line items for each order.

Columns:
    • OrderItemID (PK)
    • OrderID (FK → Order.OrderID)
    • ISBN (FK → BookTranslation.ISBN)
    • Quantity (>0)
    • UnitPrice

Indexes:
    • IDX_OrderItems_OrderID – improves order detail retrieval.
    • IDX_OrderItems_BookID – improves book sales lookups.

----------------------------------------------------------------------------------------------
TABLE: Invoice
----------------------------------------------------------------------------------------------
Purpose:
    Stores billing information for completed orders.

Columns:
    • InvoiceID (PK, identity starting at 100000)
    • OrderID (FK → Order.OrderID, unique)
    • CustomerID (FK → Customer.CustomerID)
    • InvoiceDate (default GETDATE)
    • BillingAddress
    • TotalAmount

Indexes:
    • idx_Invoice_Order – fast lookup by OrderID.
    • idx_Invoice_Customer – fast lookup by CustomerID.

Notes:
    • One invoice per order (enforced by unique constraint on OrderID).

********************************************************************************************/


CREATE TABLE Genre (
    GenreID INT IDENTITY(100,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500)
);

go

CREATE TABLE Book (
    BookID INT IDENTITY(1000,1) PRIMARY KEY,
    
    GenreID INT NOT NULL,
    

    CONSTRAINT FK_Book_Genre
        FOREIGN KEY (GenreID) REFERENCES Genre(GenreID)
);

go

CREATE TABLE BookTranslation (
    BookID INT NOT NULL,
    ISBN VARCHAR(20) NOT NULL UNIQUE,
    LanguageCode CHAR(2) NOT NULL,
    Title NVARCHAR(255) NOT NULL,
    
    Description NVARCHAR(MAX) NULL,
    PublishDate DATE NULL,
    DefaultPrice DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_BookTranslation PRIMARY KEY (ISBN),

    CONSTRAINT FK_BookTranslation_Book
        FOREIGN KEY (BookID) REFERENCES Book(BookID)
);
go

create nonclustered index IDX_BookTranslation_Bookid
on BookTranslation (Bookid)
go

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1000,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Address NVARCHAR(500),
    Phone NVARCHAR(50)
);

go

CREATE TABLE Review (
    ReviewID INT IDENTITY(1000,1) PRIMARY KEY,
    BookID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX),
    ReviewDate DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Review_Book
        FOREIGN KEY (BookID) REFERENCES Book(BookID),

    CONSTRAINT FK_Review_Customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

go

create nonclustered index IDX_Review_Bookid
on Review (Bookid)
go

create nonclustered index IDX_Review_CustomerID
on Review (CustomerID)
go



CREATE TABLE PriceSchedule (
    PriceScheduleID INT IDENTITY(1,1) PRIMARY KEY,
    ISBN VARCHAR(20) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Price DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_PriceSchedule_Book
        FOREIGN KEY (ISBN) REFERENCES BookTranslation(ISBN )
);
go

create nonclustered index IDX_PriceSchedule_Bookid
on PriceSchedule (ISBN)
go

CREATE TABLE [Order] (
    OrderID INT IDENTITY(10000,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(12,2) NOT NULL DEFAULT 0,

    CONSTRAINT FK_Order_Customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

create nonclustered index IDX_Order_CustomerID
on [Order] (CustomerID)
go

CREATE TABLE OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ISBN VARCHAR(20) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_OrderItem_Order
        FOREIGN KEY (OrderID) REFERENCES [Order](OrderID),

    CONSTRAINT FK_OrderItem_Book
        FOREIGN KEY (ISBN) REFERENCES BookTranslation(ISBN)
);

go

create nonclustered index IDX_OrderItems_OrderID
on OrderItems (OrderID)
go

create nonclustered index IDX_OrderItems_BookID
on OrderItems (ISBN)
go

CREATE TABLE Invoice (
    InvoiceID INT IDENTITY(100000,1) PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    InvoiceDate DATETIME NOT NULL DEFAULT GETDATE(),
    BillingAddress NVARCHAR(500),
    TotalAmount DECIMAL(12,2) NOT NULL,

    CONSTRAINT FK_Invoice_Order
        FOREIGN KEY (OrderID) REFERENCES [Order](OrderID),

    CONSTRAINT FK_Invoice_Customer
        FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID)
);

go

CREATE NONCLUSTERED INDEX idx_Invoice_Order
    ON Invoice(OrderID)

go

CREATE NONCLUSTERED INDEX idx_Invoice_Customer
    ON Invoice(CustomerID)
go