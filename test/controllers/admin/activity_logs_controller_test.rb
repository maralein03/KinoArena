require "test_helper"

module Admin
  class ActivityLogsControllerTest < ActionDispatch::IntegrationTest
    test "NFA-4 Kunde hat keinen Zugriff auf das Protokoll" do
      sign_in_as users(:customer)
      get admin_activity_logs_path

      assert_response :redirect
    end

    test "Admin sieht Protokolleintraege" do
      ActivityLog.record(action: "test_event", user: users(:admin), description: "Testeintrag")

      sign_in_as users(:admin)
      get admin_activity_logs_path

      assert_response :success
      assert_match(/test_event/, response.body)
    end

    test "Protokoll laesst sich nach Aktion filtern" do
      ActivityLog.record(action: "alpha_event", user: users(:admin))
      ActivityLog.record(action: "beta_event", user: users(:admin))

      sign_in_as users(:admin)
      get admin_activity_logs_path, params: { action_filter: "alpha_event" }

      assert_response :success
      assert_select "tbody td span", text: "alpha_event"
      assert_select "tbody td span", text: "beta_event", count: 0
    end
  end
end
