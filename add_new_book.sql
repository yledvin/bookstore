/********************************************************************************************
Procedure:      usp_Add_New_Book
Author:         Yevgeniy Ledvin
Purpose:        Inserts a new Book record (when @BookID = 0) and/or inserts a new 
                BookTranslation row for an existing or newly created book.

Core Behavior:
1. Validates that:
   - The supplied @Genre exists in dbo.Genre.
   - The supplied @BookID exists (when @BookID <> 0).
   - The supplied @ISBN does not already exist in dbo.BookTranslation.

2. Creates a new Book row when @BookID = 0 by:
       INSERT INTO Book (GenreID)
       SELECT GenreID FROM Genre WHERE Name = @Genre
   Then retrieves the newly created BookID.

3. Inserts a new translation row into dbo.BookTranslation for the specified language.

4. Uses TRY/CATCH with THROW to ensure proper error propagation.

---------------------------------------------------------------------------------------------
Parameters:
    @BookID        INT (default 0)
                   - 0  → create a new Book record.
                   - >0 → add a translation to an existing Book.

    @ISBN          VARCHAR(20)
                   - Must be unique across BookTranslation.

    @LanguageCode  CHAR(2)
                   - Language of the translation (e.g., 'EN', 'RU', 'FR').

    @Title         NVARCHAR(255)
                   - Title of the book in the specified language.

    @Description   NVARCHAR(MAX)
                   - Description in the specified language.

    @PublishDate   DATE
                   - Publication date for this translation.

    @DefaultPrice  DECIMAL(10,2)
                   - Base price for this translation.

    @Genre         NVARCHAR(100)
                   - Name of the genre; must exist in dbo.Genre.

---------------------------------------------------------------------------------------------
Validation Logic:
    - Genre existence check:
          IF NOT EXISTS (SELECT 1 FROM Genre WHERE Name = @Genre)
              RAISERROR('Genre does not exists in Genre table', 16, 1)

    - Book existence check (only when @BookID <> 0):
          IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = @BookID)
              RAISERROR('BookID does not exists', 16, 1)

    - ISBN uniqueness check:
          IF EXISTS (SELECT 1 FROM BookTranslation WHERE ISBN = @ISBN)
              RAISERROR('ISBN exists already', 16, 1)

---------------------------------------------------------------------------------------------
Insert Logic:
    - When @BookID = 0:
          INSERT INTO Book (GenreID)
          SELECT GenreID FROM Genre WHERE Name = @Genre

          SET @BookID = (SELECT MAX(BookID) FROM Book)

    - Always inserts a translation:
          INSERT INTO BookTranslation (BookID, ISBN, LanguageCode, Title, Description,
                                       PublishDate, DefaultPrice)
          VALUES (@BookID, @ISBN, @LanguageCode, @Title, @Description,
                  @PublishDate, @DefaultPrice)

---------------------------------------------------------------------------------------------
Error Handling:
    - TRY/CATCH block captures:
          ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
          ERROR_LINE(), ERROR_MESSAGE(), ERROR_PROCEDURE()

    - Prints diagnostic information for debugging.

    - Re-throws the original error using THROW to preserve severity and state.


********************************************************************************************/



CREATE OR ALTER PROCEDURE usp_Add_New_Book

	@BookID int=0,
	@ISBN varchar(20),@LanguageCode char(2),@Title nvarchar(255),@Description nvarchar(max),@PublishDate date,@DefaultPrice decimal(10,2),@Genre nvarchar(100)
	AS

BEGIN
SET NOCOUNT ON;

BEGIN TRY
if not exists (select [Name] from Genre where [Name]=@Genre)
    BEGIN 
        RAISERROR('Genre does not exists in Genre table',16,1)
    END
if not exists (select BookID from Book where BookID=@bookid) and @BookID <>0
    BEGIN 
        RAISERROR('BookID does not exists',16,1)
    END
if exists (select ISBN from BookTranslation where ISBN=@ISBN)
    BEGIN 
        RAISERROR('ISBN exists already',16,1)
    END

if @Bookid =0
	begin
		insert into book (GenreID) 
		select [GenreID] from [dbo].[Genre]
		where [Name]=@Genre
		set @Bookid=(select max([BookID]) from book)
	end

insert into [dbo].[BookTranslation](
		[BookID]
      ,[ISBN]
      ,[LanguageCode]
      ,[Title]
      ,[Description]
      ,[PublishDate]
      ,[DefaultPrice])
values (@BookID, @ISBN ,@LanguageCode,@Title,@Description ,@PublishDate,@DefaultPrice )
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

/*
exec usp_Add_New_Book @ISBN='300-555-2933' ,@LanguageCode='EN',@Title=N'The Silent Library',
@Description=N'A gripping mystery about a forgotten library where every book hides a secret. When a young historian uncovers a missing manuscript, she is drawn into a web of clues that reveal a truth long buried.' ,@PublishDate='04-20-1955',@DefaultPrice=15.99,@Genre='Fiction'

exec usp_Add_New_Book @Bookid=1000,@ISBN='300-555-2934' ,@LanguageCode='RU',@Title=N'Russian Version',
@Description=N'Захватывающий детектив о заброшенной библиотеке, в которой каждая книга хранит свою тайну. Когда молодой историк находит пропавшую рукопись, она оказывается втянута в цепочку загадок, ведущих к давно скрытой правде.' ,@PublishDate='04-20-1958',@DefaultPrice=15.99,@Genre='Fiction'

exec usp_Add_New_Book @Bookid=1000,@ISBN='300-555-2935' ,@LanguageCode='FR',@Title=N'La Bibliothèque Silencieuse',
@Description=N'Un roman mystérieux sur une bibliothèque oubliée où chaque livre renferme un secret. Lorsqu’une jeune historienne découvre un manuscrit disparu, elle se retrouve entraînée dans une série d’indices révélant une vérité enfouie depuis longtemps.' ,@PublishDate='04-20-1958',@DefaultPrice=15.99,@Genre='Fiction'

exec usp_Add_New_Book @ISBN='300-555-2933-8' ,@LanguageCode='EN',@Title=N'The Last Ember',
@Description=N'An epic adventure following an archaeologist who discovers a glowing ember hidden inside ancient ruins. As she traces its origin, she uncovers a forgotten civilization and a power that could reshape the world.' ,@PublishDate='04-20-1995',@DefaultPrice=15.99,@Genre='Fiction'

exec usp_Add_New_Book @Bookid=1001,@ISBN='300-555-2934-9' ,@LanguageCode='BR',@Title=N'A Última Brasa',
@Description=N'Uma aventura épica sobre uma arqueóloga que encontra uma brasa brilhante escondida em ruínas antigas. Ao investigar sua origem, ela descobre uma civilização esquecida e um poder capaz de mudar o destino do mundo.' ,@PublishDate='04-20-1998',@DefaultPrice=15.99,@Genre='Fiction'

exec usp_Add_New_Book @Bookid=1001,@ISBN='300-555-2935-2' ,@LanguageCode='FR',@Title=N' La Dernière Braise',
@Description=N'Une aventure épique où une archéologue découvre une braise lumineuse cachée dans des ruines anciennes. En cherchant son origine, elle révèle une civilisation oubliée et un pouvoir capable de transformer le monde.' ,@PublishDate='04-20-1998',@DefaultPrice=15.99,@Genre='Fiction'



exec usp_Add_New_Book @ISBN='300-556-2933-8' ,@LanguageCode='EN',@Title=N'The Last Ember',
@Description=N'An epic adventure following an archaeologist who discovers a glowing ember hidden inside ancient ruins. As she traces its origin, she uncovers a forgotten civilization and a power that could reshape the world.' ,@PublishDate='04-20-1995',@DefaultPrice=15.99,@Genre='Science'

exec usp_Add_New_Book @Bookid=1002,@ISBN='300-556-2934-9' ,@LanguageCode='BR',@Title=N'A Última Brasa',
@Description=N'Uma aventura épica sobre uma arqueóloga que encontra uma brasa brilhante escondida em ruínas antigas. Ao investigar sua origem, ela descobre uma civilização esquecida e um poder capaz de mudar o destino do mundo.' ,@PublishDate='04-20-1998',@DefaultPrice=15.99,@Genre='Science'

exec usp_Add_New_Book @Bookid=1002,@ISBN='300-556-2935-2' ,@LanguageCode='FR',@Title=N' La Dernière Braise',
@Description=N'Une aventure épique où une archéologue découvre une braise lumineuse cachée dans des ruines anciennes. En cherchant son origine, elle révèle une civilisation oubliée et un pouvoir capable de transformer le monde.' ,@PublishDate='04-20-1998',@DefaultPrice=15.99,@Genre='Science'
*/