require 'rails_helper'

RSpec.describe 'Api::V1::Customers', type: :request do
  let(:valid_attributes) do
    {
      name: 'Juan Pérez',
      person_type: 'natural',
      identification: '1234567890',
      email: 'juan@example.com',
      phone: '3001234567',
      address: 'Calle 123 #45-67, Bogotá'
    }
  end

  let(:invalid_attributes) do
    {
      name: '',
      person_type: 'invalid',
      identification: '',
      email: 'invalid_email',
      address: ''
    }
  end

  describe 'GET /api/v1/customers' do
    before do
      create_list(:customer, 25)
    end

    it 'returns a successful response' do
      get '/api/v1/customers'
      expect(response).to have_http_status(:ok)
    end

    it 'returns customers in JSON:API format' do
      get '/api/v1/customers'
      json = JSON.parse(response.body)

      expect(json).to have_key('data')
      expect(json['data']).to be_an(Array)
      expect(json['data'].first).to have_key('id')
      expect(json['data'].first).to have_key('type')
      expect(json['data'].first).to have_key('attributes')
    end

    it 'paginates results' do
      get '/api/v1/customers'
      json = JSON.parse(response.body)

      expect(json).to have_key('meta')
      expect(json['meta']['current_page']).to eq(1)
      expect(json['meta']['total_pages']).to eq(2)
      expect(json['meta']['per_page']).to eq(20)
    end

    it 'allows custom per_page parameter' do
      get '/api/v1/customers', params: { per_page: 10 }
      json = JSON.parse(response.body)

      expect(json['data'].size).to eq(10)
      expect(json['meta']['per_page']).to eq(10)
    end

    it 'returns only active customers' do
      inactive = create(:customer, :inactive)
      get '/api/v1/customers'
      json = JSON.parse(response.body)

      customer_ids = json['data'].map { |c| c['id'].to_i }
      expect(customer_ids).not_to include(inactive.id)
    end
  end

  describe 'GET /api/v1/customers/:id' do
    let(:customer) { create(:customer) }

    context 'when customer exists' do
      it 'returns a successful response' do
        get "/api/v1/customers/#{customer.id}"
        expect(response).to have_http_status(:ok)
      end

      it 'returns the customer in JSON:API format' do
        get "/api/v1/customers/#{customer.id}"
        json = JSON.parse(response.body)

        expect(json['data']['id']).to eq(customer.id.to_s)
        expect(json['data']['type']).to eq('customer')
        expect(json['data']['attributes']['name']).to eq(customer.name)
        expect(json['data']['attributes']['email']).to eq(customer.email)
      end
    end

    context 'when customer does not exist' do
      it 'returns a not found response' do
        get '/api/v1/customers/99999'
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        get '/api/v1/customers/99999'
        json = JSON.parse(response.body)

        expect(json['error']['code']).to eq('customer_not_found')
        expect(json['error']['message']).to include('no fue encontrado')
      end
    end

    context 'when customer is inactive' do
      let(:inactive_customer) { create(:customer, :inactive) }

      it 'returns a not found response' do
        get "/api/v1/customers/#{inactive_customer.id}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/customers' do
    context 'with valid parameters' do
      it 'creates a new customer' do
        expect {
          post '/api/v1/customers', params: { customer: valid_attributes }
        }.to change(Customer, :count).by(1)
      end

      it 'returns a created status' do
        post '/api/v1/customers', params: { customer: valid_attributes }
        expect(response).to have_http_status(:created)
      end

      it 'returns the created customer in JSON:API format' do
        post '/api/v1/customers', params: { customer: valid_attributes }
        json = JSON.parse(response.body)

        expect(json['data']['attributes']['name']).to eq('Juan Pérez')
        expect(json['data']['attributes']['email']).to eq('juan@example.com')
        expect(json['data']['attributes']['active']).to be true
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new customer' do
        expect {
          post '/api/v1/customers', params: { customer: invalid_attributes }
        }.not_to change(Customer, :count)
      end

      it 'returns an unprocessable entity status' do
        post '/api/v1/customers', params: { customer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        post '/api/v1/customers', params: { customer: invalid_attributes }
        json = JSON.parse(response.body)

        expect(json).to have_key('errors')
        expect(json['errors']).to be_an(Array)
        expect(json['errors'].first).to have_key('field')
        expect(json['errors'].first).to have_key('message')
      end
    end

    context 'with duplicate identification' do
      let!(:existing_customer) { create(:customer, identification: '1234567890') }

      it 'returns validation error' do
        post '/api/v1/customers', params: { customer: valid_attributes }
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to have_key('errors')
      end
    end
  end

  describe 'PATCH /api/v1/customers/:id' do
    let(:customer) { create(:customer) }
    let(:new_attributes) { { name: 'María García', email: 'maria@example.com' } }

    context 'with valid parameters' do
      it 'updates the customer' do
        patch "/api/v1/customers/#{customer.id}", params: { customer: new_attributes }
        customer.reload

        expect(customer.name).to eq('María García')
        expect(customer.email).to eq('maria@example.com')
      end

      it 'returns a successful response' do
        patch "/api/v1/customers/#{customer.id}", params: { customer: new_attributes }
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated customer in JSON:API format' do
        patch "/api/v1/customers/#{customer.id}", params: { customer: new_attributes }
        json = JSON.parse(response.body)

        expect(json['data']['attributes']['name']).to eq('María García')
        expect(json['data']['attributes']['email']).to eq('maria@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'returns an unprocessable entity status' do
        patch "/api/v1/customers/#{customer.id}", params: {
          customer: { email: 'invalid_email' }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        patch "/api/v1/customers/#{customer.id}", params: {
          customer: { name: '' }
        }
        json = JSON.parse(response.body)

        expect(json).to have_key('errors')
        expect(json['errors']).to be_an(Array)
      end
    end

    context 'when customer does not exist' do
      it 'returns a not found response' do
        patch '/api/v1/customers/99999', params: { customer: new_attributes }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/customers/:id' do
    let!(:customer) { create(:customer) }

    context 'when customer exists' do
      it 'soft deletes the customer' do
        delete "/api/v1/customers/#{customer.id}"
        customer.reload

        expect(customer.active).to eq(0)
      end

      it 'returns a no content status' do
        delete "/api/v1/customers/#{customer.id}"
        expect(response).to have_http_status(:no_content)
      end

      it 'does not physically delete the customer' do
        expect {
          delete "/api/v1/customers/#{customer.id}"
        }.not_to change(Customer, :count)
      end
    end

    context 'when customer does not exist' do
      it 'returns a not found response' do
        delete '/api/v1/customers/99999'
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when customer is already inactive' do
      let!(:inactive_customer) { create(:customer, :inactive) }

      it 'returns a not found response' do
        delete "/api/v1/customers/#{inactive_customer.id}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
