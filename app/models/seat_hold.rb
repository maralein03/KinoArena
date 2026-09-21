class SeatHold < ApplicationRecord
  HOLD_DURATION = 5.minutes

  belongs_to :showtime
  belongs_to :seat
  belongs_to :user

  before_validation :assign_expiry, on: :create

  validates :expires_at, presence: true
  validate :seat_not_already_booked

  scope :active, -> { where(expires_at: Time.current..) }
  scope :expired, -> { where(expires_at: ...Time.current) }

  def self.hold!(showtime:, seat:, user:)
    release_expired!
    create!(showtime: showtime, seat: seat, user: user)
  end

  # Gibt abgelaufene Reservierungen frei und meldet die Plaetze an alle Clients.
  def self.release_expired!
    expired.includes(:showtime, :seat).each do |hold|
      showtime = hold.showtime
      seat = hold.seat
      hold.destroy
      SeatBroadcast.seat_changed(showtime, seat)
    end
  end

  def remaining_seconds
    [ (expires_at - Time.current).ceil, 0 ].max
  end

  def held_by?(other_user)
    other_user.present? && user_id == other_user.id
  end

  private

  def assign_expiry
    self.expires_at ||= HOLD_DURATION.from_now
  end

  def seat_not_already_booked
    return if showtime.nil? || seat.nil?

    errors.add(:seat, "ist bereits gebucht") if showtime.bookings.exists?(seat_id: seat.id)
  end
end
