require "test_helper"

module Admin
  class ShowtimesControllerTest < ActionDispatch::IntegrationTest
    test "NFA-4 Kunde hat keinen Zugriff auf die Spielplanverwaltung" do
      sign_in_as users(:customer)
      get admin_showtimes_path

      assert_response :redirect
    end

    test "FA-6 Admin terminiert eine neue Vorstellung" do
      sign_in_as users(:admin)

      assert_difference("Showtime.count", 1) do
        post admin_showtimes_path, params: { showtime: {
          movie_id: movies(:krimi).id,
          auditorium_id: auditoria(:hall_one).id,
          start_time: 10.days.from_now.change(hour: 18, min: 0),
          price: 17.0
        } }
      end

      assert_redirected_to admin_showtimes_path
    end

    test "kollidierende Vorstellung im selben Saal wird abgelehnt" do
      sign_in_as users(:admin)

      assert_no_difference("Showtime.count") do
        post admin_showtimes_path, params: { showtime: {
          movie_id: movies(:krimi).id,
          auditorium_id: showtimes(:evening).auditorium_id,
          start_time: showtimes(:evening).start_time,
          price: 17.0
        } }
      end

      assert_response :unprocessable_entity
    end
  end
end
