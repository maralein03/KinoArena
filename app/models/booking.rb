class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :showtime
  belongs_to :seat

  before_validation :assign_qr_code_token, on: :create
  before_validation :assign_total_price, on: :create

  validates :qr_code_token, presence: true, uniqueness: true
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :seat_id, uniqueness: { scope: :showtime_id, message: "ist für diese Vorstellung bereits gebucht" }

  validate :seat_belongs_to_showtime_auditorium

  scope :recent_first, -> { order(created_at: :desc) }

  def to_s
    "#{showtime.label} – Platz #{seat.label}"
  end

  private

  def assign_qr_code_token
    self.qr_code_token ||= SecureRandom.uuid
  end

  def assign_total_price
    self.total_price ||= showtime&.price
  end

  def seat_belongs_to_showtime_auditorium
    return if seat.nil? || showtime.nil?

    errors.add(:seat, "gehört nicht zum Saal dieser Vorstellung") if seat.auditorium_id != showtime.auditorium_id
  end
end
