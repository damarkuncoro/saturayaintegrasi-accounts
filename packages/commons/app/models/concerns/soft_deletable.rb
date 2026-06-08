# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(deleted_at: nil) }
    scope :discarded, -> { where.not(deleted_at: nil) }
  end

  def discard
    update(deleted_at: Time.current)
  end

  def undiscard
    update(deleted_at: nil)
  end

  def discarded?
    deleted_at.present?
  end
end
