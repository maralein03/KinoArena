require "test_helper"

class ErrorHandlingTest < ActionDispatch::IntegrationTest
  include SignInHelper

  test "unbekannte Vorstellung liefert eine verstaendliche 404-Seite" do
    get showtime_path(id: 999_999)

    assert_response :not_found
    assert_select "h1", text: "Diese Seite gibt es nicht"
  end

  test "unbekannter Film liefert 404 statt Serverfehler" do
    get movie_path(id: 999_999)

    assert_response :not_found
  end

  test "unbekannte Buchung liefert 404" do
    sign_in_as users(:customer)
    get booking_path(id: 999_999)

    assert_response :not_found
  end

  test "Zugriff auf nicht existierende Ressource wird protokolliert" do
    assert_difference("ActivityLog.where(action: 'record_not_found').count", 1) do
      get showtime_path(id: 999_999)
    end
  end
end
