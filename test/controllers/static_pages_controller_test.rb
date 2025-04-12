require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url # Or static_pages_home_url if you have that named route
    assert_response :success
    assert_select "h1", "Welcome to bshelf" # Check for a key element on the home page
  end
end
