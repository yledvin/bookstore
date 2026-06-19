/********************************************************************************************
Procedure: usp_Write_review
Author:    Yevgeniy Ledvin
Purpose:   Inserts a new customer review for a specific book.

Description:
    This stored procedure records a customer review by inserting a row into dbo.Review.
    It captures the book being reviewed, the customer submitting the review, the rating,
    optional comments, and the current timestamp. All operations are wrapped in a TRY/CATCH
    block to ensure proper error handling and error propagation.

Parameters:
    @BookID       INT             – ID of the book being reviewed.
    @CustomerID   INT             – ID of the customer submitting the review.
    @Rating       INT             – Rating value (1–5).
    @Comment      NVARCHAR(MAX)   – Optional review text.

Behavior:
    • Inserts a new row into dbo.Review.
    • Automatically sets ReviewDate to the current date/time.
    • Uses SET NOCOUNT ON to suppress rowcount messages.
    • Does not validate rating range, book existence, or customer existence.

Error Handling:
    • TRY/CATCH captures SQL errors raised during the INSERT.
    • Error details printed include:
         – Procedure name
         – Line number
         – Error message
    • THROW re‑raises the original error, preserving:
         – Error number
         – Severity
         – State
    • Ensures calling applications can detect and handle failures.


********************************************************************************************/


CREATE OR ALTER PROCEDURE usp_Write_review
@BookID int,
@CustomerID int,
@Rating int,
@Comment nvarchar(max)
as 

Begin

BEGIN TRY
SET NOCOUNT ON;
if @Rating<1 or @Rating>5
BEGIN
    RAISERROR('Rating should be between 1 and 5',16,1)
END


Insert into dbo.review ([BookID]
      ,[CustomerID]
      ,[Rating]
      ,[Comment]
      ,[ReviewDate])
Values(@BookID,@CustomerID,@Rating,@Comment,getdate())
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
END;

--exec usp_Write_review 1103, 1083, 5, N'Good Book'
