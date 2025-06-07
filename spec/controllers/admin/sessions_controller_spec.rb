require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :controller do
  let!(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password', role: 'super_admin', active: true) }

  describe 'GET #new' do
    it 'renders the login template' do
      get :new
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'sets the admin session and redirects' do
        expect {
          post :create, params: { email: admin_user.email, password: 'password' }
        }.to change { session[:admin_user_id] }.from(nil)
        expect(response).to redirect_to(admin_audit_logs_path)
        log = AuditLog.where(event_type: AuditService::EVENTS[:admin_login_success]).order(created_at: :desc).first
        expect(log.event_type).to eq(AuditService::EVENTS[:admin_login_success])
        expect(log.metadata['admin_email']).to eq(admin_user.email)
      end
    end

    context 'with invalid credentials' do
      it 're-renders the login form with error' do
        post :create, params: { email: admin_user.email, password: 'wrong' }
        expect(session[:admin_user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(flash[:error]).to eq('Invalid credentials')
        log = AuditLog.where(event_type: AuditService::EVENTS[:admin_login_failed]).order(created_at: :desc).first
        expect(log.event_type).to eq(AuditService::EVENTS[:admin_login_failed])
        expect(log.metadata['attempted_email']).to eq(admin_user.email)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'clears the session and redirects to login' do
      session[:admin_user_id] = admin_user.id
      delete :destroy
      expect(session[:admin_user_id]).to be_nil
      expect(response).to redirect_to(admin_login_path)
      log = AuditLog.where(event_type: AuditService::EVENTS[:admin_logout]).order(created_at: :desc).first
      expect(log.event_type).to eq(AuditService::EVENTS[:admin_logout])
      expect(log.metadata['admin_email']).to eq(admin_user.email)
    end
  end
end
