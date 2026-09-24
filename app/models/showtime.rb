class Showtime < ApplicationRecord
  belongs_to :movie
  belongs_to :auditorium
  has_many :bookings, dependent: :destroy
  has_many :seat_holds, dependent: :destroy
  has_many :booked_seats, through: :bookings, source: :seat

  validates :start_time, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :start_time_not_in_past, on: :create
  validate :auditorium_free_at_start_time

  scope :upcoming, -> { where(start_time: Time.current..).order(:start_time) }

  def available_seats
    auditorium.seats.ordered.where.not(id: bookings.select(:seat_id))
  end

  def seat_booked?(seat)
    bookings.exists?(seat_id: seat.id)
  end

  def sold_out?
    bookings.count >= auditorium.seats.count
  end

  def label
    "#{movie&.title} – #{start_time&.strftime('%d.%m.%Y %H:%M')}"
  end

  private

  def start_time_not_in_past
    return if start_time.blank?

    errors.add(:start_time, "darf nicht in der Vergangenheit liegen") if start_time < Time.current
  end

  def auditorium_free_at_start_time
    return if start_time.blank? || auditorium_id.blank? || movie.nil?

    window_start = start_time - movie.duration_minutes.to_i.minutes
    window_end = start_time + movie.duration_minutes.to_i.minutes

    clash = Showtime.where(auditorium_id: auditorium_id)
                    .where(start_time: window_start..window_end)
                    .where.not(id: id)
                    .exists?

    errors.add(:start_time, "kollidiert mit einer anderen Vorstellung in diesem Saal") if clash
  end
end
