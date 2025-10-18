require 'rails_helper'

RSpec.describe OutboxPublisherJob, type: :job do
  describe '#perform' do
    let!(:pending_message_1) { create(:outbox_message, status: :pending, created_at: 2.hours.ago) }
    let!(:pending_message_2) { create(:outbox_message, status: :pending, created_at: 1.hour.ago) }
    let!(:published_message) { create(:outbox_message, :published) }
    let!(:failed_message) { create(:outbox_message, :failed) }

    it 'processes only pending messages' do
      described_class.new.perform

      expect(pending_message_1.reload).to be_published
      expect(pending_message_2.reload).to be_published
      expect(published_message.reload).to be_published
      expect(failed_message.reload).to be_failed
    end

    it 'processes messages in order of creation (oldest first)' do
      call_order = []

      allow_any_instance_of(described_class).to receive(:publish_to_broker) do |_, message|
        call_order << message.id
      end

      described_class.new.perform

      expect(call_order).to eq([ pending_message_1.id, pending_message_2.id ])
    end

    it 'sets published_at timestamp' do
      described_class.new.perform

      expect(pending_message_1.reload.published_at).to be_present
      expect(pending_message_2.reload.published_at).to be_present
    end

    it 'marks message as failed when error occurs' do
      allow_any_instance_of(described_class).to receive(:publish_to_broker).and_raise(StandardError.new('Connection failed'))

      described_class.new.perform

      expect(pending_message_1.reload).to be_failed
      expect(pending_message_1.error_message).to include('Connection failed')
    end

    it 'continues processing other messages when one fails' do
      allow_any_instance_of(described_class).to receive(:publish_to_broker) do |_, message|
        raise StandardError.new('Connection failed') if message.id == pending_message_1.id
      end

      described_class.new.perform

      expect(pending_message_1.reload).to be_failed
      expect(pending_message_2.reload).to be_published
    end

    it 'logs successful publication' do
      expect(Rails.logger).to receive(:info).with(/Publishing event: customer.created/).at_least(:once)

      described_class.new.perform
    end

    it 'logs failed publication' do
      allow_any_instance_of(described_class).to receive(:publish_to_broker).and_raise(StandardError.new('Connection failed'))

      expect(Rails.logger).to receive(:error).with(/Failed to publish event/).at_least(:once)

      described_class.new.perform
    end
  end

  describe '#publish_to_broker' do
    it 'logs debug message with payload' do
      message = create(:outbox_message)
      job = described_class.new

      expect(Rails.logger).to receive(:debug).with(/Would publish to broker/)

      job.send(:publish_to_broker, message)
    end
  end
end
