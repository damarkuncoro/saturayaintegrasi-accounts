require "rails_helper"

RSpec.describe Core::BasePresenter do
  let(:object) { double("Object", id: 1) }
  let(:presenter) { Core::BasePresenter.new(object) }

  describe "formatting helpers" do
    describe "#format_date" do
      it "memformat tanggal ke format default" do
        date = Date.new(2026, 6, 10)
        expect(presenter.send(:format_date, date)).to eq("10 Jun 2026")
      end

      it "mengembalikan '-' jika nil" do
        expect(presenter.send(:format_date, nil)).to eq("-")
      end
    end

    describe "#format_currency" do
      it "memformat angka ke format Rupiah" do
        expect(presenter.send(:format_currency, 1500000)).to eq("Rp 1.500.000")
      end

      it "mengembalikan '-' jika nil" do
        expect(presenter.send(:format_currency, nil)).to eq("-")
      end
    end

    describe "#format_datetime" do
      it "memformat datetime ke format default" do
        dt = DateTime.new(2026, 6, 10, 15, 30)
        expect(presenter.send(:format_datetime, dt)).to eq("10 Jun 2026 15:30")
      end
    end
  end
end
