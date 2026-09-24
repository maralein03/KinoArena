require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "Gast wird zur Anmeldung umgeleitet" do
    get users_url
    assert_redirected_to login_path
  end

  test "NFA-4 Kunde darf die Benutzerverwaltung nicht oeffnen" do
    sign_in_as users(:customer)
    get users_url
    assert_response :redirect
    assert_match(/Zugriff verweigert/, flash[:alert])
  end

  test "Admin sieht alle Benutzer" do
    sign_in_as users(:admin)
    get users_url
    assert_response :success
    assert_select "td", text: users(:customer).email_address
  end

  test "Kunde sieht das eigene Profil" do
    sign_in_as users(:customer)
    get user_url(users(:customer))
    assert_response :success
  end

  test "Kunde darf fremdes Profil nicht sehen" do
    sign_in_as users(:customer)
    get user_url(users(:other_customer))
    assert_response :redirect
  end

  test "Kunde aktualisiert eigenes Profil" do
    sign_in_as users(:customer)
    patch user_url(users(:customer)), params: { user: { name: "Neuer Name" } }

    assert_redirected_to user_path(users(:customer))
    assert_equal "Neuer Name", users(:customer).reload.name
  end

  test "Kunde kann sich nicht selbst zum Admin machen" do
    sign_in_as users(:customer)
    patch user_url(users(:customer)), params: { user: { name: "Hacker", admin: true } }

    assert_not users(:customer).reload.admin?
  end

  test "Admin loescht ein Kundenkonto" do
    sign_in_as users(:admin)

    assert_difference("User.count", -1) do
      delete user_url(users(:other_customer))
    end
    assert_redirected_to users_path
  end

  test "FA-9 Rollenaenderung wird eigens protokolliert" do
    sign_in_as users(:admin)

    assert_difference("ActivityLog.where(action: 'user_role_changed').count", 1) do
      patch user_url(users(:customer)), params: { user: { admin: true } }
    end

    assert users(:customer).reload.admin?
  end

  test "Aenderung ohne Rollenwechsel bleibt ein normaler Profileintrag" do
    sign_in_as users(:admin)

    assert_no_difference("ActivityLog.where(action: 'user_role_changed').count") do
      patch user_url(users(:customer)), params: { user: { name: "Anderer Name" } }
    end
  end
end
