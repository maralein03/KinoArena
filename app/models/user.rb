class User < ApplicationRecord
  has_secure_password

  has_many :bookings, dependent: :destroy
  has_many :activity_logs, dependent: :nullify

  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  before_validation :normalize_email_address

  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
                            format: { with: EMAIL_FORMAT, message: "ist keine gültige E-Mail-Adresse" }
  validates :name, presence: true, length: { maximum: 60 }
  validates :password, length: { minimum: 8 }, allow_nil: true

  scope :admins, -> { where(admin: true) }

  def customer?
    !admin?
  end

  def role_name
    admin? ? "Administrator" : "Kunde"
  end

  private

  def normalize_email_address
    self.email_address = email_address.to_s.strip.downcase
  end
end
