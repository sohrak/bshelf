require "httparty"
require "json"

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

    # Action to handle the ISBN lookup request from Stimulus
    def lookup_isbn
      isbn = params[:isbn].to_s.gsub(/[^0-9X]/i, "")

      if isbn.blank?
        render json: { error: "ISBN parameter is missing" }, status: :bad_request
        return
      end

      # Define URLs
      url_isbn = "https://openlibrary.org/isbn/#{isbn}.json"
      url_api = "https://openlibrary.org/api/books?bibkeys=ISBN:#{isbn}&format=json&jscmd=data"

      book_data = {}
      error_message = nil

      begin
        # Try the /isbn/ endpoint using HTTParty
        # HTTParty follows redirects by default
        response_isbn = HTTParty.get(url_isbn, format: :json, # Specify expected format
                                    headers: { "Accept" => "application/json" }) # Good practice

        if response_isbn.success? # Checks for 2xx status codes
          book_data = map_openlibrary_data(response_isbn.parsed_response, :isbn_endpoint)
        elsif response_isbn.code == 404
          # If /isbn/ endpoint fails with 404, try the /api/books endpoint
          response_api = HTTParty.get(url_api, format: :json,
                                      headers: { "Accept" => "application/json" })

          if response_api.success?
            api_data = response_api.parsed_response
            data = api_data["ISBN:#{isbn}"] # Extract nested data
            if data
              book_data = map_openlibrary_data(data, :api_endpoint)
            else
              error_message = "Book data not found using API endpoint for ISBN #{isbn}."
            end
          elsif response_api.code == 404
            error_message = "Book not found on Open Library for ISBN #{isbn}."
          else
            # Handle other API endpoint errors
            error_message = "Open Library API request failed (API Endpoint): #{response_api.code} #{response_api.message}"
            Rails.logger.error "OpenLibrary API Error: Code=#{response_api.code}, Body=#{response_api.body}"
          end
        else
          # Handle other ISBN endpoint errors (non-404, non-2xx)
          error_message = "Open Library API request failed (ISBN Endpoint): #{response_isbn.code} #{response_isbn.message}"
          Rails.logger.error "OpenLibrary ISBN Error: Code=#{response_isbn.code}, Body=#{response_isbn.body}"
        end

      rescue JSON::ParserError => e # HTTParty might raise this if response isn't valid JSON
        error_message = "Failed to parse response from Open Library."
        Rails.logger.error "OpenLibrary JSON Parse Error: #{e.message}"
      rescue StandardError => e # Catch other potential network/HTTParty errors
        error_message = "Could not connect to Open Library or process request: #{e.message}"
        Rails.logger.error "OpenLibrary Connection/Request Error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      end

      # Render JSON response
      if error_message
        render json: { error: error_message }, status: :not_found # Or :internal_server_error depending on error
      elsif book_data.empty?
         render json: { error: "No usable book data found for ISBN #{isbn}." }, status: :not_found
      else
        render json: book_data
      end
    end

  private
    # Helper method to map Open Library data to our form fields
    # Adjust this based on the exact structure variations you encounter
    def map_openlibrary_data(data, source_endpoint)
      mapped_data = {}

      # Title
      mapped_data[:title] = data["title"]

      # Author(s) - often an array of {name: "..."} or just strings
      authors = data["authors"] || []
      if authors.is_a?(Array) && !authors.empty?
        # Check if elements are hashes with a 'name' key or 'key' key
        if authors.first.is_a?(Hash) && authors.first.key?("name")
          mapped_data[:author] = authors.map { |a| a["name"] }.compact.join(", ")
        elsif authors.first.is_a?(Hash) && authors.first.key?("key")
          # Fallback: extract name from key like "/authors/OL12345A" -> "OL12345A"
          mapped_data[:author] = authors.map { |a| a["key"]&.split("/")&.last }.compact.join(", ")
        else # Assume it might be an array of strings (less common)
          mapped_data[:author] = authors.join(", ")
        end
      elsif data["by_statement"].present? # Fallback for some formats
          mapped_data[:author] = data["by_statement"].gsub(/^by\s+/i, "").gsub(/;$/, "").strip
      end


      # Publisher(s) - often an array of strings or {name: "..."}
      publishers = data["publishers"] || []
      if publishers.is_a?(Array) && !publishers.empty?
          if publishers.first.is_a?(Hash) && publishers.first.key?("name")
              mapped_data[:publisher] = publishers.map { |p| p["name"] }.compact.join(", ")
          else # Assume array of strings
              mapped_data[:publisher] = publishers.map(&:to_s).compact.join(", ")
          end
      elsif data["publish_places"].is_a?(Array) && !data["publish_places"].empty? && mapped_data[:publisher].blank?
          # Sometimes publisher info is hidden in publish_places
          mapped_data[:publisher] = data["publish_places"].map(&:to_s).compact.join(", ")
      end


      # Publication Date - format varies ('YYYY', 'Month DD, YYYY', etc.)
      # Keep as string for flexibility in the text field
      mapped_data[:publication_date] = data["publish_date"]

      # Page Count
      mapped_data[:page_count] = data["number_of_pages"] || data["pagination"] # API endpoint might use 'pagination'

      # Genre/Subjects - often an array of strings or {name: "..."}
      subjects = data["subjects"] || []
      if subjects.is_a?(Array) && !subjects.empty?
          if subjects.first.is_a?(Hash) && subjects.first.key?("name")
              mapped_data[:genre] = subjects.map { |s| s["name"] }.compact.first(3).join(", ") # Take first few
          else # Assume array of strings
              mapped_data[:genre] = subjects.map(&:to_s).compact.first(3).join(", ")
          end
      end

      # Description (optional) - might be a string or a hash {type: ..., value: ...}
      description = data["description"]
      if description.is_a?(Hash) && description.key?("value")
        mapped_data[:description] = description["value"]
      elsif description.is_a?(String)
        mapped_data[:description] = description
      elsif data["notes"].is_a?(String) # Fallback to notes
          mapped_data[:description] = data["notes"]
      elsif data["notes"].is_a?(Hash) && data["notes"].key?("value")
          mapped_data[:description] = data["notes"]["value"]
      end


      # Remove nil values before returning
      mapped_data.compact
    end

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
