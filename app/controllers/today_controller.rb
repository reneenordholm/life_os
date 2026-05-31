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

    @capture_date = Date.current
    @capture_content = @daily_log&.content

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
    Rails.logger.warn(e.full_message)
    message = Rails.env.development? ? e.message : "Calendar sync is not configured."
    redirect_to root_path, alert: message
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    redirect_to root_path, alert: "Calendar sync failed. Please try again."
  end

  def save_daily_log
    date = Date.iso8601(params[:date].to_s)
    content = params[:content].to_s.strip

    if content.blank?
      redirect_to root_path, alert: "Daily log content cannot be blank."
      return
    end

    DailyLogService.create_or_update_for_date(date, content)

    redirect_to root_path, notice: "Daily log saved successfully."
  rescue Date::Error
    redirect_to root_path, alert: "Please choose a valid date."
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    redirect_to root_path, alert: "Daily log could not be saved. Please try again."
  end
end
