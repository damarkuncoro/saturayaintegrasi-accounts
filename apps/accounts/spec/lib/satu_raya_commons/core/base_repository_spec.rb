require "rails_helper"

RSpec.describe Core::BaseRepository do
  # Mock repository untuk testing menggunakan model Identity::User yang sudah ada
  before(:all) do
    class TestUserRepository < Core::BaseRepository
      protected
      def model_class; ::Identity::User; end
      def to_entity(user)
        Struct.new(:id, :email).new(user.id, user.email)
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestUserRepository)
  end

  let(:repository) { TestUserRepository.new }
  let(:tenant) { create(:tenant) }
  let!(:user) { create(:user, tenant: tenant, email: "test-repo@example.com") }

  describe "#find" do
    it "mengembalikan entity jika record ditemukan" do
      entity = repository.find(user.id)
      expect(entity).to be_present
      expect(entity.id).to eq(user.id)
      expect(entity.email).to eq(user.email)
    end

    it "mengembalikan nil jika record tidak ditemukan" do
      expect(repository.find(0)).to be_nil
    end
  end

  describe "#all" do
    it "mengembalikan semua record sebagai entity" do
      entities = repository.all
      expect(entities).to be_an(Array)
      expect(entities.map(&:id)).to include(user.id)
    end
  end

  describe "#paginate" do
    it "mengembalikan data terpaginasi dan metadata" do
      result = repository.paginate(page: 1, per_page: 1)
      expect(result[:data]).to be_an(Array)
      expect(result[:data].size).to eq(1)
      expect(result[:meta][:total_count]).to be >= 1
      expect(result[:meta][:current_page]).to eq(1)
    end
  end

  describe "#delete" do
    it "menghapus record dari database" do
      id = user.id
      # Identity::User menyertakan SoftDeletable
      repository.delete(id)
      expect(::Identity::User.find(id).deleted_at).to be_present
    end
  end

  describe "Normalizable integration" do
    it "memiliki akses ke method normalisasi" do
      expect(repository.send(:normalize_email, "  REPO@Example.COM  ")).to eq("repo@example.com")
    end
  end
end
