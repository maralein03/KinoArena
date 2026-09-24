class Seat < ApplicationRecord
  belongs_to :auditorium
  has_many :bookings, dependent: :restrict_with_error
  has_many :seat_holds, dependent: :destroy

  validates :row, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: { scope: [ :auditorium_id, :row ] }

  scope :ordered, -> { order(:row, :number) }

  def label
    "#{row}#{number}"
  end
end
