class TodayController < ApplicationController
  def index
    today = Date.current.iso8601

    @daily_log = Document
      .where(doc_type: "daily_log")
      .find_by("metadata @> ?", { "date" => today }.to_json)

    @calendar_events = [
      {
        title: "Morning Standup",
        starts_at: "9:00 AM"
      },
      {
        title: "1:1 Meeting",
        starts_at: "1:00 PM"
      }
    ]
  end
end
