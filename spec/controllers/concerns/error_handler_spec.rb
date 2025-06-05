require 'rails_helper'

RSpec.describe ErrorHandler, type: :controller do
  controller(ApplicationController) do
    include ErrorHandler

    def index
      raise StandardError, 'boom'
    end

    def missing
      params.require(:foo)
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'missing' => 'anonymous#missing'
    end
  end

  it 'renders error message for StandardError' do
    get :index
    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to include('boom')
  end

  it 'handles ParameterMissing' do
    get :missing, format: :json
    expect(response).to have_http_status(:bad_request)
    json = JSON.parse(response.body)
    expect(json['error']).to include('Missing parameter')
  end
end
