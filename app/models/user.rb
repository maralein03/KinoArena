class User < ApplicationRecord
  has_secure_password

  has_many :bookings, dependent: :destroy
  has_many :seat_holds, dependent: :destroy
  has_many :activity_logs, dependent: :nullify

  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  PASSWORD_RESET_VALIDITY = 15.minutes
  PASSWORD_RESET_COOLDOWN = 2.minutes

  # Der Token wird aus dem Passwort-Hash abgeleitet und verfaellt deshalb
  # automatisch, sobald das Passwort geaendert wurde.
  generates_token_for :password_reset, expires_in: PASSWORD_RESET_VALIDITY do
    password_salt&.last(10)
  end

  before_validation :normalize_email_address

  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
                            format: { with: EMAIL_FORMAT, message: "ist keine gültige E-Mail-Adresse" }
  validates :name, presence: true, length: { maximum: 60 }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :at_least_one_admin_remains

  scope :admins, -> { where(admin: true) }

  def customer?
    !admin?
  end

  def role_name
    admin? ? "Administrator" : "Kunde"
  end

  def last_admin?
    admin? && self.class.admins.where.not(id: id).none?
  end

  # Verhindert, dass durch wiederholtes Absenden des Formulars beliebig viele
  # gueltige Reset-Links erzeugt werden.
  def password_reset_throttled?
    password_reset_sent_at.present? && password_reset_sent_at > PASSWORD_RESET_COOLDOWN.ago
  end

  def start_password_reset!
    update_column(:password_reset_sent_at, Time.current)
    generate_token_for(:password_reset)
  end

  private

  def normalize_email_address
    self.email_address = email_address.to_s.strip.downcase
  end

  # Ohne diese Pruefung koennte sich der einzige Administrator selbst zum
  # Kunden herabstufen und der Admin-Bereich waere fuer niemanden mehr erreichbar.
  def at_least_one_admin_remains
    return unless persisted? && admin_was && !admin?
    return if self.class.admins.where.not(id: id).exists?

    errors.add(:admin, "darf nicht entzogen werden – es muss mindestens ein Administrator bleiben")
  end
end
