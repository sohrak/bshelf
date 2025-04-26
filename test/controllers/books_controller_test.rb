require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  # Use fixtures for test data
  fixtures :books

  setup do
    # Example: Get one of the fixture books for show/edit/update/destroy tests
    @book = books(:one)
    @searchable_book = books(:searchable)
  end

  # --- Index Action Tests ---

  test "should get index" do
    get books_url
    assert_response :success
    assert_not_nil assigns(:books), "@books should be assigned"
    assert_not_nil assigns(:pagy), "@pagy should be assigned"
    assert_select "h1", "Book Collection" # Check for a key element
  end

  test "should get index via browse path" do
    get browse_books_url
    assert_response :success
    assert_select "h1", "Book Collection"
  end

  test "index should filter by genre" do
    get books_url, params: { genre_filter: "Fiction" }
    assert_response :success
    assigned_books = assigns(:books)
    assert assigned_books.all? { |b| b.genre == "Fiction" }, "All assigned books should have the genre 'Fiction'"
    assert_includes assigned_books, books(:one)
    assert_includes assigned_books, books(:another_fiction)
    assert_not_includes assigned_books, books(:two) # Non-Fiction
  end

  test "index should filter by author" do
    get books_url, params: { author_filter: "Author Alpha" }
    assert_response :success
    assigned_books = assigns(:books)
    assert assigned_books.all? { |b| b.author == "Author Alpha" }, "All assigned books should have the author 'Author Alpha'"
    assert_includes assigned_books, books(:one)
    assert_includes assigned_books, books(:another_fiction)
    assert_not_includes assigned_books, books(:two) # Author Beta
  end

  test "index should search by title query" do
    get books_url, params: { query: "Searchable" }
    assert_response :success
    assigned_books = assigns(:books)
    assert_includes assigned_books, @searchable_book, "Should find the searchable book by title"
    assert_equal 1, assigned_books.count, "Should only find one book matching 'Searchable' in title"
  end

   test "index should search by isbn query" do
    get books_url, params: { query: "SEARCHME" } # Case-insensitive part of ISBN
    assert_response :success
    assigned_books = assigns(:books)
    assert_includes assigned_books, @searchable_book, "Should find the searchable book by ISBN"
    assert_equal 1, assigned_books.count, "Should only find one book matching 'SEARCHME' in ISBN"
  end

  test "index should sort by title ascending by default" do
    get books_url
    assert_response :success
    assigned_books = assigns(:books)
    # Assuming default pagination shows at least 2 books
    # Check if titles are alphabetically sorted (or reverse if needed)
    # This depends on fixture data and pagination size
    # Example: Check first two if pagination allows
    if assigned_books.size >= 2
       assert assigned_books.first.title <= assigned_books.second.title
    end
    # A more robust check might involve fetching all and checking order
    all_books_sorted = Book.order(title: :asc).pluck(:id)
    assigned_ids = assigned_books.map(&:id)
    # Check if the assigned IDs appear in the correct relative order
    assert_equal all_books_sorted.slice(0, assigned_ids.length), assigned_ids
  end

  test "index should sort by author descending" do
    get books_url, params: { sort: "author", direction: "desc" }
    assert_response :success
    assigned_books = assigns(:books)
    all_books_sorted = Book.order(author: :desc).pluck(:id)
    assigned_ids = assigned_books.map(&:id)
    assert_equal all_books_sorted.slice(0, assigned_ids.length), assigned_ids
  end

  # --- Show Action Tests ---

  test "should show book" do
    get book_url(@book)
    assert_response :success
    assert_equal @book, assigns(:book), "@book should be assigned with the correct book"
    assert_select "h1", @book.title # Check for title on the page
  end

  test "should redirect if book not found" do
    get book_url(id: -1) # Non-existent ID
    assert_response :redirect
    assert_redirected_to books_url
    assert_not_nil flash[:alert]
  end

  # --- New Action Tests ---

  test "should get new" do
    get new_book_url
    assert_response :success
    assert_instance_of Book, assigns(:book), "@book should be a new Book instance"
  end

  # --- Create Action Tests ---

  test "should create book with valid parameters" do
    # Assert difference in Book.count before/after the block
    assert_difference("Book.count", 1) do
      post books_url, params: {
        book: {
          title: "Newly Created Book",
          author: "Creator Test",
          isbn: "999-9999999999",
          genre: "Meta",
          publication_date: Date.today
          # Add other valid attributes as needed
        }
      }
    end

    # Check redirection after successful creation
    assert_redirected_to book_url(Book.last)
    assert_equal "Book was successfully created.", flash[:notice]
  end

  test "should not create book with invalid parameters" do
    # Assert no difference in Book.count
    assert_no_difference("Book.count") do
      post books_url, params: {
        book: {
          title: "", # Invalid: Title is required
          author: "Creator Test"
        }
      }
    end

    # Should re-render the 'new' template with unprocessable_entity status
    assert_response :unprocessable_entity # Status code 422
    assert_template :new # Check if the new form is rendered again
    assert_select "aside ul li", /Title can't be blank/ # Check for error message display
  end

  test "should destroy book" do
    # Assert that the number of Book records decreases by 1
    assert_difference("Book.count", -1) do
      # Send a DELETE request to the destroy action's route
      delete book_url(@book)
    end

    # Assert that the response redirects to the books index page
    assert_redirected_to books_url

    # Optional: Assert that the flash notice is set correctly
    assert_equal "Book was successfully deleted.", flash[:notice]
  end
end
