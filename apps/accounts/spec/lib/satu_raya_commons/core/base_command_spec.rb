require "rails_helper"

RSpec.describe Core::BaseCommand do
  # Memberikan nama pada kelas agar ActiveModel tidak error
  before(:all) do
    class TestCommand < Core::BaseCommand
      attribute :email, :string
      attribute :first_name, :string
      attribute :phone, :string

      normalize :email, with: :email
      normalize :first_name, with: :text
      normalize :phone, with: :phone

      validates :email, presence: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestCommand)
  end

  describe ".call" do
    it "melakukan normalisasi atribut secara otomatis" do
      command = TestCommand.call(
        email: "  USER@Example.COM  ",
        first_name: "  Budi  ",
        phone: "0812-3456-7890"
      )

      expect(command.email).to eq("user@example.com")
      expect(command.first_name).to eq("Budi")
      expect(command.phone).to eq("081234567890")
    end

    it "tetap menjalankan validasi" do
      command = TestCommand.call(email: "")
      expect(command.failure?).to be true
      expect(command.errors[:email]).to be_present
    end
  end
end
