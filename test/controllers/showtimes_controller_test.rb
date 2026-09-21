require "test_helper"

class ShowtimesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get showtimes_index_url
    assert_response :success
  end

  test "should get show" do
    get showtimes_show_url
    assert_response :success
  end
end
