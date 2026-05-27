class TodayController < ApplicationController
  def index
    today = Date.current.iso8601

    @greeting =
      case Time.current.hour
      when 5...12
        "Good morning"
      when 12...17
        "Good afternoon"
      else
        "Good evening"
      end

    @daily_log = Document
      .where(doc_type: "daily_log")
      .where("metadata ->> 'date' = ?", today)
      .order(id: :desc)
      .first

    @calendar_events = CalendarEvent
      .where(starts_at: Date.current.all_day)
      .order(:starts_at)
  end

  def sync_calendar
    CalendarEventSyncService.call(
      start_time: Time.current.beginning_of_day,
      end_time: Time.current.end_of_day
    )

    redirect_to root_path, notice: "Calendar synced successfully."
  end
end
