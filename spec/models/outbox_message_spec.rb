require 'rails_helper'

RSpec.describe OutboxMessage, type: :model do
  describe 'validations' do
    subject { build(:outbox_message) }

    it { should validate_presence_of(:aggregate_id) }
    it { should validate_presence_of(:aggregate_type) }
    it { should validate_presence_of(:event_type) }
    it { should validate_presence_of(:payload) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, published: 1, failed: 2) }
  end

  describe 'scopes' do
    let!(:pending_message) { create(:outbox_message, status: :pending) }
    let!(:published_message) { create(:outbox_message, :published) }
    let!(:failed_message) { create(:outbox_message, :failed) }

    describe '.pending' do
      it 'returns only pending messages' do
        expect(OutboxMessage.pending).to include(pending_message)
        expect(OutboxMessage.pending).not_to include(published_message)
        expect(OutboxMessage.pending).not_to include(failed_message)
      end
    end

    describe '.published' do
      it 'returns only published messages' do
        expect(OutboxMessage.published).to include(published_message)
        expect(OutboxMessage.published).not_to include(pending_message)
        expect(OutboxMessage.published).not_to include(failed_message)
      end
    end

    describe '.failed' do
      it 'returns only failed messages' do
        expect(OutboxMessage.failed).to include(failed_message)
        expect(OutboxMessage.failed).not_to include(pending_message)
        expect(OutboxMessage.failed).not_to include(published_message)
      end
    end

    describe '.by_status' do
      it 'returns messages by specific status' do
        expect(OutboxMessage.by_status(:pending)).to include(pending_message)
        expect(OutboxMessage.by_status(:published)).to include(published_message)
        expect(OutboxMessage.by_status(:failed)).to include(failed_message)
      end
    end

    describe '.by_aggregate' do
      it 'returns messages for specific aggregate type and id' do
        message = create(:outbox_message, aggregate_type: 'Customer', aggregate_id: '123')
        other_message = create(:outbox_message, aggregate_type: 'Order', aggregate_id: '456')

        expect(OutboxMessage.by_aggregate('Customer', '123')).to include(message)
        expect(OutboxMessage.by_aggregate('Customer', '123')).not_to include(other_message)
      end
    end

    describe '.oldest_first' do
      it 'orders messages by created_at ascending' do
        OutboxMessage.delete_all  # Clear previous test data
        old_message = create(:outbox_message, created_at: 2.days.ago)
        new_message = create(:outbox_message, created_at: 1.day.ago)

        messages = OutboxMessage.oldest_first.to_a
        expect(messages.first).to eq(old_message)
        expect(messages.last).to eq(new_message)
      end
    end
  end

  describe 'instance methods' do
    describe '#mark_as_published!' do
      let(:message) { create(:outbox_message, status: :pending) }

      it 'updates status to published' do
        expect { message.mark_as_published! }.to change { message.reload.status }.from('pending').to('published')
      end

      it 'sets published_at timestamp' do
        expect { message.mark_as_published! }.to change { message.reload.published_at }.from(nil)
      end

      it 'sets published_at to current time' do
        message.mark_as_published!
        expect(message.reload.published_at).to be_within(1.second).of(Time.current)
      end
    end

    describe '#mark_as_failed!' do
      let(:message) { create(:outbox_message, status: :pending) }
      let(:error_msg) { 'Connection timeout' }

      it 'updates status to failed' do
        expect { message.mark_as_failed!(error_msg) }.to change { message.reload.status }.from('pending').to('failed')
      end

      it 'sets error_message' do
        expect { message.mark_as_failed!(error_msg) }.to change { message.reload.error_message }.from(nil).to(error_msg)
      end

      it 'handles exception objects' do
        error = StandardError.new('Test error')
        message.mark_as_failed!(error)
        expect(message.reload.error_message).to eq('Test error')
      end
    end

    describe '#parsed_payload' do
      it 'parses JSON payload' do
        payload_data = { id: 1, name: 'Test' }
        message = create(:outbox_message, payload: payload_data.to_json)

        expect(message.parsed_payload).to eq(payload_data.stringify_keys)
      end

      it 'returns empty hash for invalid JSON' do
        message = create(:outbox_message, payload: 'invalid json')
        expect(message.parsed_payload).to eq({})
      end
    end
  end

  describe 'database' do
    it 'has a valid factory' do
      expect(build(:outbox_message)).to be_valid
    end

    it 'has a valid published factory' do
      expect(build(:outbox_message, :published)).to be_valid
    end

    it 'has a valid failed factory' do
      expect(build(:outbox_message, :failed)).to be_valid
    end
  end
end
