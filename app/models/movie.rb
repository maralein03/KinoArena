class Movie < ApplicationRecord
  has_many :showtimes, dependent: :restrict_with_error

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true
  validates :duration_minutes, presence: true,
                               numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 600 }
  validates :poster_url, format: { with: %r{\Ahttps://\S+\z}, message: "muss eine https-URL sein" }, allow_blank: true

  def duration_label
    "#{duration_minutes / 60}h #{duration_minutes % 60}m"
  end

  def to_s
    title
  end
end
