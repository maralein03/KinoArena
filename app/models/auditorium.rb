class Auditorium < ApplicationRecord
  has_many :seats, dependent: :destroy
  has_many :showtimes, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :total_seats, presence: true,
                          numericality: { only_integer: true, greater_than: 0 }

  def to_s
    name
  end
end
