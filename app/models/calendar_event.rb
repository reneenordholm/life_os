class CalendarEvent < ApplicationRecord
  validates :title, presence: true
  validates :starts_at, presence: true
  validate :ends_at_cannot_be_before_starts_at

  private

  def ends_at_cannot_be_before_starts_at
    return if ends_at.nil? || starts_at.nil?
    return unless ends_at < starts_at

    errors.add(:ends_at, "must be greater than or equal to starts_at")
  end
end
