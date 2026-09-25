require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "gueltiger Benutzer kann gespeichert werden" do
    user = User.new(name: "Neu", email_address: "Neu@Example.test", password: "passwort123")
    assert user.save
    assert_equal "neu@example.test", user.email_address
  end

  test "E-Mail-Adresse muss eindeutig sein" do
    user = User.new(name: "Doppelt", email_address: users(:customer).email_address, password: "passwort123")
    assert_not user.valid?
    assert_includes user.errors.attribute_names, :email_address
  end

  test "Passwort braucht mindestens 8 Zeichen" do
    user = User.new(name: "Kurz", email_address: "kurz@example.test", password: "1234567")
    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end

  test "Rollen werden korrekt unterschieden" do
    assert users(:admin).admin?
    assert users(:customer).customer?
    assert_equal "Administrator", users(:admin).role_name
    assert_equal "Kunde", users(:customer).role_name
  end

  test "NFA-4 dem letzten Administrator kann die Rolle nicht entzogen werden" do
    admin = users(:admin)

    assert_not admin.update(admin: false)
    assert_includes admin.errors.attribute_names, :admin
    assert admin.reload.admin?
  end

  test "Rollenentzug ist erlaubt, solange ein weiterer Administrator bleibt" do
    users(:other_customer).update!(admin: true)

    assert users(:admin).update(admin: false)
  end

  test "NFA-7 Reset-Token identifiziert den Benutzer und verfaellt nach Ablauf" do
    user = users(:customer)
    token = user.generate_token_for(:password_reset)

    assert_equal user, User.find_by_token_for(:password_reset, token)

    travel (User::PASSWORD_RESET_VALIDITY + 1.minute) do
      assert_nil User.find_by_token_for(:password_reset, token)
    end
  end

  test "NFA-7 Reset-Token wird durch eine Passwortaenderung entwertet" do
    user = users(:customer)
    token = user.generate_token_for(:password_reset)
    user.update!(password: "ganzneuespasswort")

    assert_nil User.find_by_token_for(:password_reset, token)
  end

  test "NFA-7 Reset-Anfragen sind kurzzeitig gesperrt" do
    user = users(:customer)
    assert_not user.password_reset_throttled?

    user.start_password_reset!
    assert user.password_reset_throttled?

    travel (User::PASSWORD_RESET_COOLDOWN + 1.minute) do
      assert_not user.password_reset_throttled?
    end
  end
end
