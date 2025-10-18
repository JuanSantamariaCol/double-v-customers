module OutboxPublisher
  extend ActiveSupport::Concern

  included do
    after_create :publish_created_event
    after_update :publish_updated_event
  end

  private

  def publish_created_event
    create_outbox_message("created")
  end

  def publish_updated_event
    # Detectar si el campo 'active' cambió a 0 (soft delete)
    if saved_change_to_active? && active == 0
      create_outbox_message("deleted")
    else
      create_outbox_message("updated")
    end
  end

  def create_outbox_message(action)
    OutboxMessage.create!(
      aggregate_id: id.to_s,
      aggregate_type: self.class.name,
      event_type: "#{self.class.name.downcase}.#{action}",
      payload: outbox_payload.to_json,
      status: :pending
    )
  end

  def outbox_payload
    {
      id: id,
      name: name,
      person_type: person_type,
      identification: identification,
      email: email,
      phone: phone,
      address: address,
      active: active,
      timestamp: Time.current.iso8601
    }
  end
end
