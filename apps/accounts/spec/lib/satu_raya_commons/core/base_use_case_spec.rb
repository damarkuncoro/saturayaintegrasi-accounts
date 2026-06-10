require "rails_helper"

RSpec.describe Core::BaseUseCase do
  # Mock use case untuk testing
  before(:all) do
    class TestUseCase < Core::BaseUseCase
      transactional!

      def perform_execute(should_fail: false, error_msg: "Error")
        if should_fail
          raise StandardError, error_msg
        else
          success("Success Data")
        end
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestUseCase)
  end

  describe ".call" do
    it "dapat dipanggil langsung melalui class method" do
      result = TestUseCase.call
      expect(result).to be_success
      expect(result.value).to eq("Success Data")
    end
  end

  describe "#execute" do
    it "menangani exception secara otomatis dan mengembalikan failure" do
      result = TestUseCase.call(should_fail: true, error_msg: "Boom!")
      expect(result).to be_failure
      expect(result.code).to eq(:system_error)
      expect(result.error).to eq("Terjadi kesalahan sistem.")
    end

    it "menjalankan dalam transaksi jika transactional! diset" do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      TestUseCase.call
    end
  end
end
