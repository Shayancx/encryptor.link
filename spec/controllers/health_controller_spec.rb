require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #show' do
    context 'when all checks pass' do
      it 'returns healthy status' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)

        get :show, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('healthy')
        expect(json['checks']['database']).to be true
        expect(json['checks']['disk_space']).to be true
      end
    end

    context 'when database check fails' do
      it 'returns service unavailable status' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError)

        get :show, format: :json

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('unhealthy')
        expect(json['checks']['database']).to be false
      end
    end

    context 'when disk space check fails' do
      it 'returns service unavailable status' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)
        allow_any_instance_of(HealthController).to receive(:check_disk_space).and_return(false)

        get :show, format: :json

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('unhealthy')
        expect(json['checks']['disk_space']).to be false
      end
    end
  end
end
