/********************************************************************************************
Procedure:      usp_Create_New_Price_Rules
Author:         Yevgeniy Ledvin
Purpose:        Creates a new price rule for a specific ISBN within a defined date range,
                ensuring no overlapping price schedules exist.

Description:
    Inserts a new row into dbo.PriceSchedule after validating:
        • ISBN exists in BookTranslation.
        • Date range is valid (EndDate > StartDate).
        • No overlapping price rules exist for the same ISBN.

    Uses TRY/CATCH with THROW to ensure proper error propagation and debugging visibility.

---------------------------------------------------------------------------------------------
Parameters:
    @ISBN        VARCHAR(20)
                 - Must exist in BookTranslation.
                 - Must not already have an overlapping price rule.

    @StartDate   DATE
                 - Beginning of the price rule period.

    @EndDate     DATE
                 - End of the price rule period.
                 - Must be strictly greater than @StartDate.

    @Price       DECIMAL(10,2)
                 - Price to apply during the specified period.

---------------------------------------------------------------------------------------------
Validation Logic:
    • ISBN existence:
          IF NOT EXISTS (SELECT 1 FROM BookTranslation WHERE ISBN = @ISBN)
              RAISERROR('ISBN does not exists', 16, 1)

    • Date range validity:
          IF @EndDate <= @StartDate
              RAISERROR('Check dates', 16, 1)

    • Overlap detection:
          IF EXISTS (
                SELECT 1
                FROM PriceSchedule
                WHERE ISBN = @ISBN
                  AND (
                        (StartDate >= @StartDate AND StartDate < @EndDate)
                     OR (EndDate   >  @StartDate AND EndDate   <= @EndDate)
                  )
          )
              RAISERROR('Price rule overlapping for <ISBN>', 16, 1)

---------------------------------------------------------------------------------------------
Insert Logic:
    INSERT INTO PriceSchedule (ISBN, StartDate, EndDate, Price)
    VALUES (@ISBN, @StartDate, @EndDate, @Price)

---------------------------------------------------------------------------------------------
Error Handling:
    • Captures:
          ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
          ERROR_LINE(), ERROR_MESSAGE(), ERROR_PROCEDURE()

    • Prints diagnostic information for debugging.

    • Re-throws the original error using THROW to preserve severity and state.

---------------------------------------------------------------------------------------------
Notes & Recommendations:
    • Consider enforcing a UNIQUE constraint on (ISBN, StartDate, EndDate) to prevent duplicates.
    • Consider returning the newly created PriceScheduleID to the caller.
    • Consider adding logic to automatically close previous price rules when inserting a new one.

********************************************************************************************/



CREATE OR ALTER PROCEDURE usp_Create_New_Price_Rules
    @ISBN varchar(20),
    @StartDate date,
    @EndDate date,
    @Price decimal(10,2)
AS

BEGIN
SET NOCOUNT ON;

BEGIN TRY
if not exists (select ISBN from BookTranslation where ISBN=@ISBN)
    BEGIN 
        RAISERROR('ISBN does not exists',16,1)
    END

    if @EndDate<=@StartDate
    BEGIN 
        RAISERROR('Check dates',16,1)
    END
    if exists (select ISBN from PriceSchedule where ISBN=@ISBN and ((StartDate >=@StartDate and StartDate<@EndDate) or (EndDate>@StartDate and EndDate<=@EndDate)))
    BEGIN

        DECLARE @msg varchar(100)= (select CONCAT(N'Price rule overlapping for ', @ISBN))
        RAISERROR(@msg,16,1)
    END

INSERT INTO [dbo].[PriceSchedule](
	[ISBN],
	[StartDate],
	[EndDate],
	[Price]
	)
VALUES(
    @ISBN,
	@StartDate ,
	@EndDate ,
	@Price
    )

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


--exec usp_Create_New_Price_Rules '300-555-2','2026-06-05','2026-09-30',10.99

