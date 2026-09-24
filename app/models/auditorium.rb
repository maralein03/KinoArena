class Auditorium < ApplicationRecord
  MAX_ROWS = 26

  has_many :seats, dependent: :destroy
  has_many :showtimes, dependent: :restrict_with_error

  # Virtuelle Felder: aus ihnen wird der Saalplan beim Anlegen erzeugt.
  attr_accessor :row_count, :seats_per_row

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :total_seats, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :row_count, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_ROWS },
                        on: :create
  validates :seats_per_row, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 40 },
                            on: :create

  before_validation :derive_total_seats, on: :create
  after_create :generate_seats

  def rows
    seats.distinct.order(:row).pluck(:row)
  end

  def booked_seat_count
    Booking.where(seat_id: seats.select(:id)).count
  end

  def to_s
    name
  end

  private

  def derive_total_seats
    return if row_count.blank? || seats_per_row.blank?

    self.total_seats = row_count.to_i * seats_per_row.to_i
  end

  def generate_seats
    return if row_count.blank? || seats_per_row.blank?

    ("A"..."Z").first(row_count.to_i).each do |row|
      (1..seats_per_row.to_i).each do |number|
        seats.create!(row: row, number: number)
      end
    end
  end
end
