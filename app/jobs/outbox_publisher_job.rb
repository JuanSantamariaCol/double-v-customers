class OutboxPublisherJob < ApplicationJob
  queue_as :default

  def perform
    OutboxMessage.pending.oldest_first.find_each do |message|
      begin
        # TODO: Aqui se publicaria al broker (Kafka, RabbitMQ, etc)
        # Por ahora solo marcamos como publicado

        Rails.logger.info("Publishing event: #{message.event_type} for #{message.aggregate_type}##{message.aggregate_id}")

        # Simular publicación exitosa
        publish_to_broker(message)

        message.mark_as_published!
      rescue StandardError => e
        Rails.logger.error("Failed to publish event #{message.id}: #{e.message}")
        message.mark_as_failed!(e.message)
      end
    end
  end

  private

  def publish_to_broker(message)
    # TODO: Implementar integración con broker real (Kafka, RabbitMQ, etc))

    # Por ahora solo simulamos la publicacion
    Rails.logger.debug("Would publish to broker: #{message.payload}")
  end
end
