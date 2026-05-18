class CalendarEvent < ApplicationRecord
  validates :title, presence: true
  validates :starts_at, presence: true
end
