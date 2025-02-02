# High Level Design

bshelf is an application used to organize and search a book collection.

## Requirements

- Framework: Rails
- Database: SQLite
- Styling: Pico CSS
- The application main page will present a search, browse, and add a boook option. The initial MVP will not require authentication or support user accounts.
  - The search option will consist of a text box and search button. Upon entering a search query the database will be search for books that meets the search criteria. The search can be done over title, author, ISBN, book genre, etc. Or, search can be done over any category.
  - The browse option will be presented as a button.
- Search results and browsing will be displayed on a common page presenting a list of books paginated by default with 20 per books page. This pagination can be selected by the user from the options of 20, 100, or all. The page will offer sorting over any book metadata, such as title (default). There will be the option to filter books by genre, author, etc. Selecting a book from this page takes the user to the book details page.
  - The filter selection should be a drop-down based on the unique values found in the DB for each category.
- The add book page will allow the user to enter all possible book information as text fields. It will provide save and cancel buttons. Cancel will return the user to the main page. Save will take the user to the book details page.
- The book details page displays all book information in a tabular format.

### Post MVP

- Improve add book page by pulling book data from the OpenLibrary [Books API](https://openlibrary.org/dev/docs/api/books)
- Support book images
- Authentication, account creation and management
  - Support multiple users
  - Allow users to mark a book as checked out or reserved
- Deploy to AWS, GCP, etc.
  - GitHub action to deploy when new changes pushed
  - Kubernetes
- Migrate database from SQLite
