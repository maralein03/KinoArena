class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  # Fehler beim Loggen duerfen den Fachablauf nie abbrechen.
  def self.record(action:, user: nil, target: nil, description: nil, ip_address: nil)
    create!(
      action: action,
      user: user,
      target_type: target&.class&.name,
      target_id: target&.id,
      description: description,
      ip_address: ip_address
    )
  rescue StandardError => e
    Rails.logger.warn("ActivityLog konnte nicht geschrieben werden: #{e.message}")
    nil
  end

  def actor_name
    user&.email_address || "Gast"
  end

  def target_label
    return "-" if target_type.blank?

    "#{target_type} ##{target_id}"
  end
end
