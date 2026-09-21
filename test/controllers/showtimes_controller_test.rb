require "test_helper"

class ShowtimesControllerTest < ActionDispatch::IntegrationTest
  test "Programm ist oeffentlich erreichbar" do
    get showtimes_url
    assert_response :success
  end

  test "Saalplan zeigt Vorstellung an" do
    get showtime_url(showtimes(:evening))
    assert_response :success
    assert_select "h1", text: /#{movies(:dune).title}/
  end
end
