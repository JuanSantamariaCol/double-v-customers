require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    subject { build(:customer) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }

    it { should validate_presence_of(:person_type) }
    it { should define_enum_for(:person_type).with_values(natural: 0, company: 1).with_prefix(:person) }

    it { should validate_presence_of(:identification) }
    it { should validate_uniqueness_of(:identification).case_insensitive }
    it { should validate_length_of(:identification).is_at_most(50) }

    it { should validate_presence_of(:email) }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    it { should validate_length_of(:email).is_at_most(255) }

    it { should validate_length_of(:phone).is_at_most(20) }
    it { should allow_value(nil).for(:phone) }
    it { should allow_value('').for(:phone) }

    it { should validate_presence_of(:address) }
    it { should validate_length_of(:address).is_at_most(500) }
  end

  describe 'scopes' do
    let!(:active_customer) { create(:customer, active: 1) }
    let!(:inactive_customer) { create(:customer, :inactive) }
    let!(:natural_customer) { create(:customer, :natural) }
    let!(:company_customer) { create(:customer, :company) }

    describe '.actives' do
      it 'returns only active customers' do
        expect(Customer.actives).to include(active_customer)
        expect(Customer.actives).not_to include(inactive_customer)
      end
    end

    describe '.inactives' do
      it 'returns only inactive customers' do
        expect(Customer.inactives).to include(inactive_customer)
        expect(Customer.inactives).not_to include(active_customer)
      end
    end

    describe '.person_company' do
      it 'returns only company customers' do
        expect(Customer.person_company).to include(company_customer)
        expect(Customer.person_company).not_to include(natural_customer)
      end
    end

    describe '.person_natural' do
      it 'returns only natural person customers' do
        expect(Customer.person_natural).to include(natural_customer)
        expect(Customer.person_natural).not_to include(company_customer)
      end
    end
  end

  describe 'instance methods' do
    describe '#active?' do
      it 'returns true when active is 1' do
        customer = build(:customer, active: 1)
        expect(customer.active?).to be true
      end

      it 'returns false when active is 0' do
        customer = build(:customer, active: 0)
        expect(customer.active?).to be false
      end
    end

    describe '#soft_delete' do
      let(:customer) { create(:customer) }

      it 'sets active to 0' do
        expect { customer.soft_delete }.to change { customer.active }.from(1).to(0)
      end

      it 'does not delete the record from database' do
        customer.soft_delete
        expect(Customer.find_by(id: customer.id)).to be_present
      end
    end

    describe '#restore' do
      let(:customer) { create(:customer, :inactive) }

      it 'sets active to 1' do
        expect { customer.restore }.to change { customer.active }.from(0).to(1)
      end
    end
  end

  describe 'database' do
    it 'has a valid factory' do
      expect(build(:customer)).to be_valid
    end

    it 'has a valid natural person factory' do
      expect(build(:customer, :natural)).to be_valid
    end

    it 'has a valid company factory' do
      expect(build(:customer, :company)).to be_valid
    end
  end

  describe 'outbox pattern' do
    describe 'when customer is created' do
      it 'creates outbox message' do
        expect {
          create(:customer)
        }.to change(OutboxMessage, :count).by(1)
      end

      it 'creates message with correct event_type' do
        customer = create(:customer)
        message = OutboxMessage.last

        expect(message.event_type).to eq('customer.created')
      end

      it 'creates message with pending status' do
        customer = create(:customer)
        message = OutboxMessage.last

        expect(message).to be_pending
      end

      it 'creates message with correct aggregate information' do
        customer = create(:customer)
        message = OutboxMessage.last

        expect(message.aggregate_id).to eq(customer.id.to_s)
        expect(message.aggregate_type).to eq('Customer')
      end

      it 'creates message with customer data in payload' do
        customer = create(:customer, name: 'John Doe', email: 'john@example.com')
        message = OutboxMessage.last
        payload = JSON.parse(message.payload)

        expect(payload['id']).to eq(customer.id)
        expect(payload['name']).to eq('John Doe')
        expect(payload['email']).to eq('john@example.com')
        expect(payload['person_type']).to eq(customer.person_type)
        expect(payload['identification']).to eq(customer.identification)
        expect(payload['phone']).to eq(customer.phone)
        expect(payload['address']).to eq(customer.address)
        expect(payload['active']).to eq(customer.active)
        expect(payload['timestamp']).to be_present
      end
    end

    describe 'when customer is updated' do
      it 'creates outbox message' do
        customer = create(:customer)

        expect {
          customer.update(name: 'Updated Name')
        }.to change(OutboxMessage, :count).by(1)
      end

      it 'creates message with correct event_type' do
        customer = create(:customer)
        customer.update(name: 'Updated Name')
        message = OutboxMessage.last

        expect(message.event_type).to eq('customer.updated')
      end

      it 'creates message with updated data in payload' do
        customer = create(:customer)
        customer.update(name: 'Updated Name', email: 'updated@example.com')
        message = OutboxMessage.last
        payload = JSON.parse(message.payload)

        expect(payload['name']).to eq('Updated Name')
        expect(payload['email']).to eq('updated@example.com')
      end

      it 'does not create message if update fails' do
        customer = create(:customer)
        initial_count = OutboxMessage.count

        customer.update(email: 'invalid-email')

        expect(OutboxMessage.count).to eq(initial_count)
      end
    end

    describe 'when customer is deleted' do
      it 'creates outbox message' do
        customer = create(:customer)

        expect {
          customer.soft_delete
        }.to change(OutboxMessage, :count).by(1)
      end

      it 'creates message with correct event_type' do
        customer = create(:customer)
        customer.soft_delete
        message = OutboxMessage.last

        expect(message.event_type).to eq('customer.deleted')
      end

      it 'creates message with deleted customer data in payload' do
        customer = create(:customer)
        customer_id = customer.id
        customer_name = customer.name

        customer.soft_delete
        message = OutboxMessage.last
        payload = JSON.parse(message.payload)

        expect(payload['id']).to eq(customer_id)
        expect(payload['name']).to eq(customer_name)
      end
    end

    describe 'transactional consistency' do
      it 'creates both customer and outbox message in same transaction' do
        expect {
          create(:customer)
        }.to change(Customer, :count).by(1)
         .and change(OutboxMessage, :count).by(1)
      end

      it 'does not create outbox message if customer creation fails' do
        expect {
          begin
            create(:customer, email: 'invalid-email')
          rescue ActiveRecord::RecordInvalid
            # Expected to fail
          end
        }.not_to change(OutboxMessage, :count)
      end
    end
  end
end
