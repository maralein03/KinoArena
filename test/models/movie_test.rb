require "test_helper"

class MovieTest < ActiveSupport::TestCase
  test "Titel Beschreibung und Dauer sind Pflichtfelder" do
    movie = Movie.new

    assert_not movie.valid?
    assert_includes movie.errors.attribute_names, :title
    assert_includes movie.errors.attribute_names, :description
    assert_includes movie.errors.attribute_names, :duration_minutes
  end

  test "Film mit Vorstellungen kann nicht geloescht werden" do
    assert_not movies(:dune).destroy
    assert movies(:dune).persisted?
  end
end
