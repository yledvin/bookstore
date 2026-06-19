/********************************************************************************************
Function: udf_GetBookRecomendation
Author:    Yevgeniy
Purpose:   Returns recommended books based on matching genre and language.

Description:
    This inline table-valued function returns a list of recommended books that share the
    same genre as the specified @BookID and are available in the requested language.
    The function excludes the original book from the result set.

Parameters:
    @BookID     INT         – The reference book used to determine genre.
    @langcode   CHAR(2)     – ISO language code used to filter translations (e.g., 'EN').

Behavior:
    • Determines the genre of the input @BookID.
    • Returns all other books in the same genre.
    • Filters results by the specified language code.
    • Excludes the original book from recommendations.
    • Returns metadata from BookTranslation and GenreID from Book.

Returned Columns:
    • BookID          – ID of the recommended book.
    • ISBN            – ISBN of the translation.
    • Title           – Title in the requested language.
    • Description     – Description in the requested language.
    • GenreID         – Genre of the recommended book.


********************************************************************************************/



CREATE OR ALTER FUNCTION dbo.udf_GetBookRecomendation (@BookID INT, @langcode CHAR(2))
RETURNS TABLE
AS
RETURN
(
    SELECT 
    bt.BookID,
        bt.ISBN,
       
        bt.Title,
       bt.Description,
       b.GenreID
    FROM BookTranslation bt join Book b ON (bt.BookID=b.BookID)
    WHERE  [LanguageCode]=@langcode and b.genreid =(select distinct genreid from book where bookid=@BookID) and bt.bookid<>@BookID

    
);

--select * from udf_GetBookRecomendation( 1001,'FR' )