require "test_helper"

module Admin
  class AuditoriaControllerTest < ActionDispatch::IntegrationTest
    test "NFA-4 Kunde hat keinen Zugriff auf die Saalverwaltung" do
      sign_in_as users(:customer)
      get admin_auditoria_path

      assert_response :redirect
      assert_match(/Zugriff verweigert/, flash[:alert])
    end

    test "Admin sieht alle Saele" do
      sign_in_as users(:admin)
      get admin_auditoria_path

      assert_response :success
      assert_select "td", text: auditoria(:hall_one).name
    end

    test "Admin legt einen Saal an und der Saalplan wird erzeugt" do
      sign_in_as users(:admin)

      assert_difference("Auditorium.count", 1) do
        assert_difference("Seat.count", 12) do
          post admin_auditoria_path, params: { auditorium: {
            name: "Saal 3 – Lounge", row_count: 3, seats_per_row: 4
          } }
        end
      end

      auditorium = Auditorium.find_by(name: "Saal 3 – Lounge")
      assert_equal 12, auditorium.total_seats
      assert_equal %w[A B C], auditorium.rows
      assert_redirected_to admin_auditoria_path
    end

    test "Saal ohne Reihenangaben wird abgelehnt" do
      sign_in_as users(:admin)

      assert_no_difference("Auditorium.count") do
        post admin_auditoria_path, params: { auditorium: { name: "Unvollständig" } }
      end

      assert_response :unprocessable_entity
    end

    test "Saalname bleibt eindeutig" do
      sign_in_as users(:admin)

      assert_no_difference("Auditorium.count") do
        post admin_auditoria_path, params: { auditorium: {
          name: auditoria(:hall_one).name, row_count: 2, seats_per_row: 2
        } }
      end

      assert_response :unprocessable_entity
    end

    test "Umbenennen laesst den Saalplan unveraendert" do
      sign_in_as users(:admin)

      assert_no_difference("Seat.count") do
        patch admin_auditorium_path(auditoria(:hall_one)), params: {
          auditorium: { name: "Saal 1 – Premium", row_count: 99, seats_per_row: 99 }
        }
      end

      assert_equal "Saal 1 – Premium", auditoria(:hall_one).reload.name
      assert_equal 4, auditoria(:hall_one).seats.count
    end

    test "Saal mit Vorstellungen kann nicht geloescht werden" do
      sign_in_as users(:admin)

      assert_no_difference("Auditorium.count") do
        delete admin_auditorium_path(auditoria(:hall_one))
      end

      assert_match(/kann nicht gelöscht werden/, flash[:alert])
    end

    test "Saal ohne Vorstellungen kann geloescht werden" do
      leerer_saal = Auditorium.create!(name: "Testsaal leer", row_count: 2, seats_per_row: 2)
      sign_in_as users(:admin)

      assert_difference("Auditorium.count", -1) do
        delete admin_auditorium_path(leerer_saal)
      end

      assert_redirected_to admin_auditoria_path
    end
  end
end
