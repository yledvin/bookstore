/********************************************************************************************
Procedure: usp_Add_customer
Author:    Yevgeniy
Purpose:   Inserts a new customer record into dbo.Customer.

Description:
    This procedure creates a new customer entry using the provided name, email, 
    address, and phone number. It includes TRY/CATCH error handling to capture 
    and print detailed error information without terminating the batch.

Parameters:
    @Name      NVARCHAR(200)  – Customer full name
    @Email     NVARCHAR(200)  – Customer email address
    @Address   NVARCHAR(500)  – Customer physical address
    @Phone     NVARCHAR(50)   – Customer phone number

Behavior:
    • Inserts a single row into dbo.Customer.
    • Uses SET NOCOUNT ON to reduce unnecessary rowcount messages.
    • Catches and prints SQL errors including procedure name, line number, and message.

Error Handling:
    • Errors are captured in TRY/CATCH.
    • Error details are printed to the console.
    • No rethrow (THROW) is used — procedure fails silently unless PRINT output is monitored.

********************************************************************************************/

CREATE OR ALTER PROCEDURE usp_Add_customer
@Name nvarchar(200),
@email nvarchar(200),
@address nvarchar(500),
@phone nvarchar(50)
AS

BEGIN
SET NOCOUNT ON;

BEGIN TRY
Insert into [dbo].[Customer](
        [Name]
      ,[Email]
      ,[Address]
      ,[Phone])
values (
@Name ,
@email ,
@address,
@phone)
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


--exec usp_Add_customer N'Yevgeniy Ledvin',N'yledvin@hotmail.com',N'13434 Moorpark st, Sherman Oaks, CA, 91423','+1 818-981-3447'