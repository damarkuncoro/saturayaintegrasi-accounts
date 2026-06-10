require "rails_helper"

RSpec.describe UseCases::PublishUserSyncEvent, type: :model do
  let(:user) { create(:user, email: "sync_test@example.com", first_name: "John", last_name: "Doe") }

  describe "#execute" do
    it "enqueues Identity::UserSyncJob with correct payload" do
      ActiveJob::Base.queue_adapter = :test

      expect {
        described_class.new.execute(action: "create", user: user)
      }.to have_enqueued_job(Identity::UserSyncJob).with(
        hash_including(
          action: "create",
          user: hash_including(
            id: user.id,
            email: "sync_test@example.com",
            first_name: "John",
            last_name: "Doe",
            role: "user",
            active: true
          )
        )
      )
    end
  end
end
