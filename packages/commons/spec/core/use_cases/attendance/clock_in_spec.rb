# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCases::Attendance::ClockIn do
  let(:attendance_repo) { instance_double(Repositories::Attendance::AttendanceRepository) }
  let(:contract_repo) { instance_double(Repositories::Recruitment::ContractRepository) }
  let(:use_case) { described_class.new(attendance_repo: attendance_repo, contract_repo: contract_repo) }
  
  let(:worker_profile_id) { 1 }
  let(:tenant_id) { 1 }

  describe "#call" do
    context "when already clocked in" do
      before do
        allow(attendance_repo).to receive(:find_today_attendance).with(worker_profile_id).and_return(double)
      end

      it "returns failure" do
        result = use_case.call(worker_profile_id: worker_profile_id)
        expect(result.success?).to be false
        expect(result.error).to eq("Anda sudah melakukan Clock In hari ini.")
      end
    end

    # Additional tests would go here
  end
end
