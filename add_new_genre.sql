/********************************************************************************************
Procedure: usp_Add_New_Genre
Author:    Yevgeniy Ledvin
Purpose:   Inserts a new genre record into dbo.Genre.

Description:
    This stored procedure inserts a new genre using the provided name and description.
    It uses a TRY/CATCH block to capture runtime errors and rethrows them using THROW,
    ensuring proper error propagation to the calling application or process.

Parameters:
    @Name         NVARCHAR(100)  – Genre name (required).
    @Description  NVARCHAR(300)  – Optional genre description.

Behavior:
    • Inserts a single row into dbo.Genre.
    • Uses SET NOCOUNT ON to suppress rowcount messages.
    • Performs a direct INSERT without validation or uniqueness checks.

Error Handling:
    • TRY/CATCH captures SQL errors raised during the INSERT.
    • Error details printed include procedure name, line number, and message text.
    • THROW re‑raises the original error, preserving error number and state.
    • This ensures calling layers (API, app, service) can detect and handle failures.


    ********************************************************************************************/


CREATE OR ALTER PROCEDURE usp_Add_New_Genre
	@Name nvarchar(100),
	@Description nvarchar(300)

AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY
DECLARE @n int=(select count(*) from Genre where TRIM(name)=@Name)
--print @n
if @n=0
BEGIN
Insert into [dbo].[Genre]([Name],[Description])
Values(@Name,@Description)
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
END;

--exec usp_Add_New_Genre 'Science', 'Scientific literature'
--exec usp_Add_New_Genre 'Action', 'Action literature'