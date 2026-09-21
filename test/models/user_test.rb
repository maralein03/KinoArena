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
end
