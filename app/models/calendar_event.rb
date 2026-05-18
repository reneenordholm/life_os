class CalendarEvent < ApplicationRecord
  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, comparison: { greater_than_or_equal_to: :starts_at }, allow_nil: true
end
