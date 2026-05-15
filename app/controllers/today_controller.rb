class TodayController < ApplicationController
  def index
    today = Date.current.iso8601

    @daily_log = Document.find_by(
      doc_type: "daily_log",
      metadata: { date: today }
    )

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
