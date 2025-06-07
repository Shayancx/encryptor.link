require 'rails_helper'

RSpec.describe Admin::AuditLogsController, type: :controller do
  let!(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password', role: 'super_admin', active: true) }
  let!(:audit_log) { create(:audit_log, metadata: { foo: 'bar' }) }

  before do
    session[:admin_user_id] = admin_user.id
    relation = AuditLog.all
    def relation.page(*); self; end
    def relation.per(*); self; end
    def relation.current_page; 1; end
    def relation.total_pages; 1; end
    def relation.total_count; count; end
    allow(controller).to receive(:filtered_audit_logs).and_return(relation)
    allow(relation).to receive(:includes).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
  end

  describe 'GET #index' do
    it 'returns audit logs list' do
      get :index, format: :json
      expect(response).to have_http_status(:ok)
      expect(assigns(:audit_logs)).to include(audit_log)
    end

    it 'supports JSON format' do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json['audit_logs'].first['event_type']).to eq(audit_log.event_type)
      expect(json['pagination']['current_page']).to eq(1)
    end
  end

  describe 'GET #show' do
    it 'returns the requested log with metadata' do
      get :show, params: { id: audit_log.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['metadata']['foo']).to eq('bar')
      log = AuditLog.where(event_type: AuditService::EVENTS[:audit_log_viewed]).order(created_at: :desc).first
      expect(log.event_type).to eq(AuditService::EVENTS[:audit_log_viewed])
      expect(log.metadata['viewed_log_id']).to eq(audit_log.id)
      expect(log.metadata['admin_email']).to eq(admin_user.email)
    end
  end
end
