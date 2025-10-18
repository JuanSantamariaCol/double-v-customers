require 'rails_helper'

RSpec.describe 'Api::V1::Health', type: :request do
  describe 'GET /api/v1/health' do
    context 'when service is healthy' do
      it 'returns a successful response' do
        get '/api/v1/health'
        expect(response).to have_http_status(:ok)
      end

      it 'returns health status information' do
        get '/api/v1/health'
        json = JSON.parse(response.body)

        expect(json['status']).to eq('ok')
        expect(json['service']).to eq('customers-service')
        expect(json['database']).to eq('connected')
        expect(json).to have_key('timestamp')
        expect(json).to have_key('version')
      end
    end

    context 'when database is unavailable' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError.new('Connection failed'))
      end

      it 'returns a service unavailable response' do
        get '/api/v1/health'
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'returns error information' do
        get '/api/v1/health'
        json = JSON.parse(response.body)

        expect(json['status']).to eq('error')
        expect(json['database']).to eq('disconnected')
        expect(json).to have_key('error')
      end
    end
  end
end
