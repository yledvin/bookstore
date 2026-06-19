/********************************************************************************************
Database:       BookStore
Author:         Yevgeniy
Purpose:        Creates the BookStore database with a multi‑file data architecture optimized
                for scalability, IO distribution, and future growth.

Description:
    This script creates the BookStore database using:
        • One primary data file (BookStore.mdf)
        • Seven secondary data files (BookStore1.ndf … BookStore7.ndf)
        • One transaction log file (BookStore_log.ldf)

    The multi‑file design allows SQL Server to distribute allocation activity across multiple
    physical files, improving performance for write‑heavy workloads and reducing contention
    on allocation structures (PFS, GAM, SGAM).

File Layout:
    PRIMARY:
        • BookStore.mdf   – Main data file

    SECONDARY FILEGROUP (default):
        • BookStore1.ndf
        • BookStore2.ndf
        • BookStore3.ndf
        • BookStore4.ndf
        • BookStore5.ndf
        • BookStore6.ndf
        • BookStore7.ndf

    LOG:
        • BookStore_log.ldf

File Settings:
    • Initial size: 8192 KB for each data file
    • Growth: 10 MB increments (FILEGROWTH = 10240 KB)
    • Unlimited max size for data files
    • Log file max size: 2048 GB, growth 30 MB

Behavior:
    • Database created with default containment (NONE)
    • Catalog collation inherits server default
    • Ledger is disabled (not required for this workload)

Notes:
    • This layout is ideal for OLTP workloads with moderate to high concurrency.
    • Ensure files reside on fast storage (SSD/NVMe) for best performance.
    • Consider separating log file onto its own disk for optimal throughput.

********************************************************************************************/


USE [master]
GO

/****** Object:  Database [BookStore]    Script Date: 6/1/2026 12:14:46 PM ******/
CREATE DATABASE [BookStore]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'BookStore', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore1', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore1.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore2', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore2.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore3', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore3.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore4', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore4.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore5', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore5.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore6', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore6.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ),
( NAME = N'BookStore7', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore7.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB )
 LOG ON 
( NAME = N'BookStore_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\DATA\BookStore_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 30720KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO

