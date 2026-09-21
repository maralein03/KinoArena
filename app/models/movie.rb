class Movie < ApplicationRecord
  has_many :showtimes, dependent: :restrict_with_error

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true
  validates :duration_minutes, presence: true,
                               numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 600 }

  def to_s
    title
  end
end
