class OutboxMessage < ApplicationRecord
  # Validations
  validates :aggregate_id, presence: true
  validates :aggregate_type, presence: true
  validates :event_type, presence: true
  validates :payload, presence: true
  validates :status, presence: true

  # Enums
  enum :status, { pending: 0, published: 1, failed: 2 }

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_aggregate, ->(type, id) { where(aggregate_type: type, aggregate_id: id) }
  scope :oldest_first, -> { order(created_at: :asc) }

  # Methods
  def mark_as_published!
    update!(status: :published, published_at: Time.current)
  end

  def mark_as_failed!(error)
    update!(status: :failed, error_message: error.to_s)
  end

  def parsed_payload
    JSON.parse(payload)
  rescue JSON::ParserError
    {}
  end
end
