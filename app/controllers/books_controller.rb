class BooksController < ApplicationController
  before_action :set_book, only: [ :show, :destroy, :edit, :update ]
  before_action :set_filter_options, only: [ :index ]

  # GET /books or /browse
  def index
    scope = Book.all

    # Search
    if params[:query].present?
      query = "%#{params[:query].downcase}%" # Case-insensitive search
      scope = scope.where(
        "LOWER(title) LIKE :query OR LOWER(author) LIKE :query OR LOWER(isbn) LIKE :query OR LOWER(genre) LIKE :query",
        query: query
      )
    end

    # Filtering
    if params[:genre_filter].present?
      scope = scope.where(genre: params[:genre_filter])
    end
    if params[:author_filter].present?
      scope = scope.where(author: params[:author_filter])
    end
    # Add more filters here if needed

    # Sorting - Define allowable columns
    sortable_columns = %w[title author genre isbn publication_date page_count]
    sort_column = params[:sort].presence_in(sortable_columns) || "title"
    sort_direction = params[:direction].presence_in(%w[asc desc]) || "asc"
    scope = scope.order(sort_column => sort_direction)

    # Pagination
    items_per_page = params[:items].presence_in(%w[20 100])&.to_i || 20
    @pagy, @books = pagy(scope, items: items_per_page)

    # Handle 'all' items - overrides pagination if selected
    if params[:items] == "all"
       @pagy, @books = pagy(scope, items: scope.count) # Paginate the filtered/sorted scope with all items
    end
  end

  # GET /books/1
  def show
    # @book is set by before_action
  end

  # GET /books/new
  def new
    @book = Book.new
  end


  def edit
    # @book is set by before_action
  end

  # POST /books
  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      # Re-render the form with errors
      render :new, status: :unprocessable_entity
    end
  end


  def update
    if @book.update(book_params)
      redirect_to @book, notice: "Book was successfully updated."
    else
      # Re-render the form with errors
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy! # Use destroy! to raise an error if deletion fails

    respond_to do |format|
      format.html { redirect_to books_url, notice: "Book was successfully deleted." }
      format.json { head :no_content }
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    # Optional: Handle cases where deletion might fail (e.g., due to dependent records)
    respond_to do |format|
      format.html { redirect_to @book, alert: "Book could not be deleted: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to books_path, alert: "Book not found."
    end

    # Only allow a list of trusted parameters through.
    def book_params
      params.require(:book).permit(
        :title, :author, :isbn, :genre, :description,
        :publication_date, :publisher, :page_count
      )
    end

    # Set distinct values for filter dropdowns
    def set_filter_options
      @genres = Book.distinct.pluck(:genre).compact.sort
      @authors = Book.distinct.pluck(:author).compact.sort
      # Add more distinct fields if needed for future filters
    end

    # Helper method for sortable table headers
    def sortable(column, title = nil)
      title ||= column.titleize
      # Determine the direction for the link
      current_column = params[:sort] == column
      current_direction_asc = params[:direction] == "asc"
      direction = current_column && current_direction_asc ? "desc" : "asc"

      # Visual indicator for sorted column
      indicator = ""
      if current_column
        indicator = current_direction_asc ? " ▲" : " ▼"
      end

      # Build link preserving existing filter/search/pagination params
      # Explicitly use view_context to access the link_to helper
      merged_params = params.permit(:query, :genre_filter, :author_filter, :items).merge(sort: column, direction: direction)
      view_context.link_to(title + indicator, merged_params) # Changed this line
    end
    helper_method :sortable # Make it available in views
end
