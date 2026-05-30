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
    now = Time.current

    CalendarEventSyncService.call(
      start_time: now.beginning_of_day,
      end_time: now.end_of_day
    )

    redirect_to root_path, notice: "Calendar synced successfully."
  rescue ArgumentError => e
    Rails.logger.warn(e.message)
    redirect_to root_path, alert: e.message
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    redirect_to root_path, alert: "Calendar sync failed. Please try again."
  end
end
