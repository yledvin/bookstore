
/********************************************************************************************
Procedure: usp_Customer_Order
Author:    Yevgeniy Ledvin
Purpose:   Creates or updates a customer order, adds order items, applies pricing rules,
           validates input, and optionally completes checkout with tax‑adjusted invoicing.

Description:
    This stored procedure manages the full lifecycle of an order. It supports:
        • Creating a new order (@neworder = 1)
        • Adding an item to an existing order
        • Validating ISBN, customer, quantity, and invoice duplication
        • Applying promotional pricing from PriceSchedule when active
        • Calculating order totals
        • Applying tax to the final invoice amount
        • Generating an invoice during checkout
        • Executing all operations inside a transaction for consistency

Parameters:
    @neworder        BIT             – 1 = create new order; 0 = use existing @orderid.
    @orderid         INT             – Existing order ID (ignored if @neworder = 1).
    @ISBN            VARCHAR(20)     – Book ISBN to add to the order.
    @CustomerID      INT             – Customer placing the order.
    @BillingAddress  NVARCHAR(500)   – Optional billing address (defaults to customer address).
    @qty             INT             – Quantity of the item.
    @checkout        BIT             – 1 = finalize order and create invoice.
    @tax             DECIMAL(10,2)   – Tax percentage to apply (e.g., 8.25).

Validation Logic:
    • ISBN must exist in BookTranslation.
    • CustomerID must exist in Customer.
    • Quantity must be > 0.
    • Invoice must not already exist for the given OrderID + CustomerID.
    • Validation failures raise custom RAISERROR messages.

Pricing Logic:
    • If a PriceSchedule rule is active (current date between StartDate and EndDate),
      the promotional price is used.
    • Otherwise, DefaultPrice from BookTranslation is used.

Checkout Logic:
    • Computes @orderAmount from OrderItems.
    • Updates dbo.Order.TotalAmount.
    • Uses provided @BillingAddress or defaults to the customer's stored address.
    • Inserts a new invoice with:
          TotalAmount = ROUND(@orderAmount * ((100 + @tax) / 100.0), 2)

Error Handling:
    • TRY/CATCH block wraps the entire operation.
    • On error:
         – Error details are printed (procedure, line, message).
         – THROW re‑raises the original error for proper propagation.
         – Transaction is rolled back if active.


********************************************************************************************/




CREATE OR ALTER PROCEDURE usp_Customer_Order
	@neworder bit =0,
	@orderid int=0,
	@ISBN varchar(20),
	@Customerid int,
	@BillingAddress nvarchar(500)='',
	@qty int=0,
	@checkout bit=0,
    @tax decimal(10,2)=0

	AS
	BEGIN
SET NOCOUNT ON;
Declare @BookPrice decimal(10,2)=0
Declare @orderAmount decimal(12,2)=0



BEGIN TRY
if not exists (select ISBN from BookTranslation where ISBN=@ISBN)
    BEGIN 
        RAISERROR('ISBN does not exists',16,1)
    END
if not exists(select CustomerID from Customer where CustomerID=@Customerid)
    BEGIN
        RAISERROR('This customer does not exists',16,1)
    END
if @qty<=0
    BEGIN
        RAISERROR('Quantity shoud be greater than 0',16,1)
    END
if exists (select 1 from Invoice where OrderID=@orderid and CustomerID=@Customerid)
    BEGIN
        RAISERROR('This invoice has been created already',16,1)
    END
    
BEGIN TRAN


if @neworder=1
	BEGIN
	INSERT INTO [dbo].[Order]([CustomerID],[OrderDate],[TotalAmount])
		VALUES(@Customerid,GETDATE(),0)
		set @orderid = (select max([OrderID]) from [dbo].[Order] where [CustomerID]=@Customerid)
	END
	


set @BookPrice = (select  
		  case 
				when isnull(ps.[price],0)<>0 and GETDATE()>[StartDate] and GETDATE()<[EndDate] then [price] 
				else [DefaultPrice] end as pr from [dbo].[BookTranslation] bt left join [dbo].[PriceSchedule] ps on (bt.ISBN=ps.ISBN) where  bt.ISBN=@ISBN)

	
	
	INSERT INTO [dbo].[OrderItems]([OrderID],[ISBN],[Quantity],[UnitPrice])
	VALUES(@orderid,@ISBN,@qty,@BookPrice)

	if @checkout =1
		BEGIN 
			set @orderAmount=(select sum([Quantity]*[UnitPrice]) from [dbo].[OrderItems] where [OrderID]=@orderid)
			UPDATE [dbo].[Order]
			set [TotalAmount] = @orderAmount
			where [OrderID]=@orderid
		
			if LEN(@BillingAddress)=0
				BEGIN
					set @BillingAddress=(SELECT [Address] from [dbo].[Customer] where Customerid=@Customerid)
				END

			INSERT INTO [dbo].[Invoice] ([OrderID],[CustomerID],[InvoiceDate],[BillingAddress],[TotalAmount])
			VALUES (@orderid,@Customerid,GETDATE(),@BillingAddress,round(@OrderAmount*((100+@tax)/100.0),2))
		END
        
		COMMIT TRANSACTION

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
        if @@TRANCOUNT>0
			ROLLBACK TRAN
END CATCH;
END;


--exec usp_Customer_Order @neworder = 1 , @orderid=0, @ISBN ='978-0000-498-1', @Customerid =1088,	@qty =5, @checkout=1, @tax=10
	