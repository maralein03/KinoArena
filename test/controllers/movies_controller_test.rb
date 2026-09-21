require "test_helper"

class MoviesControllerTest < ActionDispatch::IntegrationTest
  test "FA-2 Filmdetails sind oeffentlich erreichbar" do
    get movie_url(movies(:dune))

    assert_response :success
    assert_select "h1", text: movies(:dune).title
  end

  test "zeigt kommende Vorstellungen des Films" do
    get movie_url(movies(:dune))

    assert_select "a[href=?]", showtime_path(showtimes(:evening))
  end
end
