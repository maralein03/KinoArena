require "test_helper"

module Admin
  class MoviesControllerTest < ActionDispatch::IntegrationTest
    test "NFA-4 Kunde hat keinen Zugriff auf die Filmverwaltung" do
      sign_in_as users(:customer)
      get admin_movies_path

      assert_response :redirect
      assert_match(/Zugriff verweigert/, flash[:alert])
    end

    test "FA-5 Admin legt einen Film an" do
      sign_in_as users(:admin)

      assert_difference("Movie.count", 1) do
        post admin_movies_path, params: { movie: {
          title: "Neuer Film", description: "Beschreibung", duration_minutes: 95
        } }
      end

      assert_redirected_to admin_movies_path
    end

    test "NFA-2 veraltete lock_version fuehrt zu Konfliktmeldung" do
      sign_in_as users(:admin)
      movie = movies(:krimi)
      stale_version = movie.lock_version
      movie.update!(title: "Zwischenzeitlich geaendert")

      patch admin_movie_path(movie), params: { movie: {
        title: "Meine Aenderung",
        description: movie.description,
        duration_minutes: movie.duration_minutes,
        lock_version: stale_version
      } }

      assert_response :conflict
      assert_equal "Zwischenzeitlich geaendert", movie.reload.title
    end
  end
end
