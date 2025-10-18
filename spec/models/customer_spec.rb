require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    subject { build(:customer) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }

    it { should validate_presence_of(:person_type) }
    it { should define_enum_for(:person_type).with_values(natural: 0, empresa: 1).with_prefix(:person) }

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
    let!(:empresa_customer) { create(:customer, :empresa) }

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

    describe '.person_empresa' do
      it 'returns only empresa customers' do
        expect(Customer.person_empresa).to include(empresa_customer)
        expect(Customer.person_empresa).not_to include(natural_customer)
      end
    end

    describe '.person_natural' do
      it 'returns only natural person customers' do
        expect(Customer.person_natural).to include(natural_customer)
        expect(Customer.person_natural).not_to include(empresa_customer)
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

    it 'has a valid empresa factory' do
      expect(build(:customer, :empresa)).to be_valid
    end
  end
end
