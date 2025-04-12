require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "should be valid with required attributes" do
    book = Book.new(title: "Valid Title", author: "Valid Author")
    assert book.valid?, "Book should be valid with title and author"
  end

  test "should not be valid without a title" do
    book = Book.new(author: "Some Author")
    assert_not book.valid?, "Book should be invalid without a title"
    assert_includes book.errors[:title], "can't be blank"
  end

  test "should not be valid without an author" do
    book = Book.new(title: "Some Title")
    assert_not book.valid?, "Book should be invalid without an author"
    assert_includes book.errors[:author], "can't be blank"
  end

  test "should save a valid book" do
    book = Book.new(
      title: "The Great Test",
      author: "Tester McTest",
      isbn: "978-1234567890",
      genre: "Testing",
      description: "A book about testing.",
      publication_date: Date.today,
      publisher: "Test Press",
      page_count: 101
    )
    assert book.save, "Should successfully save a valid book"
  end

  # Add more tests here if you add more complex validations or custom methods
  # For example, if you add ISBN validation:
  # test "should not be valid with invalid ISBN format" do
  #   book = Book.new(title: "Title", author: "Author", isbn: "invalid-isbn")
  #   assert_not book.valid?
  #   assert_includes book.errors[:isbn], "format is invalid"
  # end
end
