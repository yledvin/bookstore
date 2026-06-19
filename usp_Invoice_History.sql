/********************************************************************************************
Procedure:      usp_Invoice_History
Purpose:        Returns invoice history for a customer in either:
                • Summary mode  (totals per invoice)
                • Detailed mode (line‑item breakdown via OrderItems)
                • Optional filtering by specific InvoiceID

Description:
    This procedure supports four retrieval modes based on @invoiceID and @detailed:

        1. @invoiceID = 0, @detailed = 0
              → Summary of all invoices for the customer

        2. @invoiceID = 0, @detailed = 1
              → Detailed line‑item view for all invoices

        3. @invoiceID <> 0, @detailed = 1
              → Detailed line‑item view for a specific invoice

        4. @invoiceID <> 0, @detailed = 0
              → Summary for a specific invoice

    Includes validation for customer existence and invoice existence (when provided).
    Uses TRY/CATCH with THROW for robust error propagation.

---------------------------------------------------------------------------------------------
Parameters:
    @CustomerID     INT
                    - Must exist in Customer table.

    @invoiceID      INT (default 0)
                    - 0  → return all invoices for the customer.
                    - >0 → return only the specified invoice.

    @detailed       BIT (default 0)
                    - 0 → summary mode.
                    - 1 → detailed mode (joins OrderItems).

---------------------------------------------------------------------------------------------
Validation Logic:
    • Customer must exist:
          IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
              RAISERROR('This customer does not exists', 16, 1)

    • Invoice must exist when @invoiceID <> 0:
          IF NOT EXISTS (SELECT 1 FROM Invoice WHERE InvoiceID = @invoiceID)
              RAISERROR('This invoice does not exists', 16, 1)

---------------------------------------------------------------------------------------------
Query Logic:

    1. Summary of all invoices:
          SELECT CustomerID, Name, InvoiceID, SUM(TotalAmount) AS CustomerTotal
          FROM Customer JOIN Invoice
          WHERE CustomerID = @CustomerID
          GROUP BY CustomerID, Name, InvoiceID

    2. Detailed for all invoices:
          SELECT CustomerID, Name, InvoiceID, OrderID, Quantity, UnitPrice
          FROM Customer
          JOIN Invoice
          JOIN OrderItems
          WHERE CustomerID = @CustomerID

    3. Detailed for a specific invoice:
          Same as above, filtered by InvoiceID

    4. Summary for a specific invoice:
          SELECT CustomerID, Name, InvoiceID, SUM(TotalAmount)
          FROM Customer JOIN Invoice
          WHERE CustomerID = @CustomerID AND InvoiceID = @invoiceID
          GROUP BY CustomerID, Name, InvoiceID

---------------------------------------------------------------------------------------------
Error Handling:
    • Captures:
          ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
          ERROR_LINE(), ERROR_MESSAGE(), ERROR_PROCEDURE()

    • Prints diagnostic information for debugging.

    • Re-throws the original error using THROW to preserve severity and state.

---------------------------------------------------------------------------------------------
Notes & Recommendations:
    • Consider adding ORDER BY InvoiceDate for predictable output.
    • Consider adding a @FromDate / @ToDate filter for reporting.
    • Consider returning totals per customer or per invoice as separate columns.

********************************************************************************************/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE or ALTER PROCEDURE usp_Invoice_History
	
	@Customerid int, 
	@invoiceID int = 0,
	@detailed bit=0
AS
BEGIN
	
	SET NOCOUNT ON;
    BEGIN TRY
    if not exists(select CustomerID from Customer where CustomerID=@Customerid)
    BEGIN
        RAISERROR('This customer does not exists',16,1)
    END

    if not exists (select invoiceid from Invoice where invoiceid = @invoiceID ) and @invoiceID<>0
    BEGIN
        RAISERROR('This invoice does not exists' ,16,1)
    end

	
	if @invoiceid=0 and @detailed=0
		BEGIN 
        select i.[CustomerID], c.[name], i.invoiceid, sum(i.[TotalAmount]) as CustomerTotal
		from customer c join invoice i on (c.CustomerID=i.CustomerID) 
		where c.customerid=@Customerid
		group by i.[CustomerID], c.[name], i.invoiceid
	END

	if @invoiceID=0 and @detailed=1
	BEGIN
		select i.[CustomerID], c.[name],i.invoiceid,i.[OrderID],oi.[Quantity],oi.[UnitPrice]
		from customer c join invoice i on (c.CustomerID=i.CustomerID) 
		join orderItems oi on(oi.orderid=i.OrderID)
		where c.customerid=@Customerid

	END
	if @invoiceID<>0 and @detailed=1
	BEGIN
		select i.[CustomerID], c.[name],i.invoiceid,i.[OrderID],oi.[Quantity],oi.[UnitPrice]
		from customer c join invoice i on (c.CustomerID=i.CustomerID) 
		join orderItems oi on(oi.orderid=i.OrderID)
		where c.customerid=@Customerid and i.InvoiceID=@invoiceID

	END
	if @invoiceid<>0 and @detailed=0
	BEGIN 
        select i.[CustomerID], c.[name], i.invoiceid, sum(i.[TotalAmount]) as CustomerTotal
		from customer c join invoice i on (c.CustomerID=i.CustomerID) 
		where c.customerid=@Customerid and i.InvoiceID=@invoiceID
		group by i.[CustomerID], c.[name], i.invoiceid
	END
	END TRY

BEGIN CATCH
        DECLARE 
            @ErrorNumber INT = ERROR_NUMBER(),
            @ErrorSeverity INT = ERROR_SEVERITY(),
            @ErrorState INT = ERROR_STATE(),
            @ErrorLine INT = ERROR_LINE(),
            @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(),
            @ErrorProc NVARCHAR(200) = ERROR_PROCEDURE();

        

        PRINT 'Error in procedure: ' + ISNULL(@ErrorProc, 'Unknown');
        PRINT 'Line: ' + CAST(@ErrorLine AS NVARCHAR(10));
        PRINT 'Message: ' + @ErrorMessage;
		

		THROW
END CATCH;
END


--exec usp_Invoice_History 1000
--exec usp_Invoice_History @Customerid=1083, @invoiceID  = 0,@detailed=1
--exec usp_Invoice_History @Customerid=1083, @invoiceID  = 100094,@detailed=1
--exec usp_Invoice_History @Customerid=1083, @invoiceID  = 100094,@detailed=0