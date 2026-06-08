require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_rupiah' do
    it 'formats number to Indonesian Rupiah' do
      expect(helper.format_rupiah(1000000)).to eq('Rp 1.000.000')
    end
  end

  describe '#format_date' do
    it 'formats date to Indonesian standard' do
      date = Date.new(2026, 5, 25)
      expect(helper.format_date(date)).to eq('25/05/2026')
    end

    it 'returns dash for nil date' do
      expect(helper.format_date(nil)).to eq('-')
    end
  end
end

RSpec.describe System::HealthController, type: :request do
  describe 'GET /health' do
    it 'returns status OK' do
      get '/health'
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['status']).to eq('OK')
    end
  end

  describe 'GET /ready' do
    it 'returns status READY when services are up' do
      get '/ready'
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['status']).to eq('READY')
    end
  end
end
