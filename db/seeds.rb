# db/seeds.rb
puts "Seeding database..."
Book.destroy_all # Clear existing books first

Book.create!([
  { title: "The Hobbit", author: "J.R.R. Tolkien", isbn: "978-0547928227", genre: "Fantasy", description: "A prelude to The Lord of the Rings.", publication_date: "1937-09-21", publisher: "George Allen & Unwin", page_count: 310 },
  { title: "1984", author: "George Orwell", isbn: "978-0451524935", genre: "Dystopian", description: "A novel about the dangers of totalitarianism.", publication_date: "1949-06-08", publisher: "Secker & Warburg", page_count: 328 },
  { title: "Pride and Prejudice", author: "Jane Austen", isbn: "978-0141439518", genre: "Romance", description: "A classic novel of manners.", publication_date: "1813-01-28", publisher: "T. Egerton, Whitehall", page_count: 279 },
  { title: "To Kill a Mockingbird", author: "Harper Lee", isbn: "978-0061120084", genre: "Fiction", description: "A novel about childhood innocence and racial injustice.", publication_date: "1960-07-11", publisher: "J. B. Lippincott & Co.", page_count: 281 },
  { title: "The Great Gatsby", author: "F. Scott Fitzgerald", isbn: "978-0743273565", genre: "Fiction", description: "A novel about the American Dream.", publication_date: "1925-04-10", publisher: "Charles Scribner's Sons", page_count: 180 },
  { title: "Moby Dick", author: "Herman Melville", isbn: "978-1503280786", genre: "Adventure", description: "The saga of Captain Ahab and his obsession with the great white whale.", publication_date: "1851-10-18", publisher: "Harper & Brothers", page_count: 635 },
  { title: "War and Peace", author: "Leo Tolstoy", isbn: "978-0140447934", genre: "Historical Fiction", description: "A novel chronicling the French invasion of Russia.", publication_date: "1869-01-01", publisher: "The Russian Messenger", page_count: 1225 },
  { title: "Brave New World", author: "Aldous Huxley", isbn: "978-0060850524", genre: "Dystopian", description: "A novel about a futuristic society.", publication_date: "1932-01-01", publisher: "Chatto & Windus", page_count: 311 }
])

puts "Seeded #{Book.count} books."
