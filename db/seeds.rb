# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
CalendarEvent.where(source: "seed").destroy_all

today = Date.current

CalendarEvent.create!(
  title: "Morning Standup",
  starts_at: today.beginning_of_day + 9.hours,
  ends_at: today.beginning_of_day + 9.hours + 30.minutes,
  location: "Zoom",
  source: "seed"
)

CalendarEvent.create!(
  title: "1:1 Meeting",
  starts_at: today.beginning_of_day + 13.hours,
  ends_at: today.beginning_of_day + 14.hours,
  location: "South Lake Union",
  source: "seed"
)

CalendarEvent.create!(
  title: "Boat Fuel Stop",
  starts_at: today.beginning_of_day + 18.hours,
  ends_at: today.beginning_of_day + 19.hours,
  location: "Seattle Marina",
  source: "seed"
)
