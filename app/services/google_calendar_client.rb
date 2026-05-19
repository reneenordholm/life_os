require "google/apis/calendar_v3"

class GoogleCalendarClient
  Calendar = Google::Apis::CalendarV3

  def initialize(calendar_id: "primary", service: Calendar::CalendarService.new, authorization: nil)
    @calendar_id = calendar_id
    @service = service
    @authorization = authorization
  end

  def events_for_range(start_time:, end_time:)
    @service.authorization ||= @authorization || authorization

    @service.list_events(
      @calendar_id,
      single_events: true,
      order_by: "startTime",
      time_min: start_time.iso8601,
      time_max: end_time.iso8601
    ).items
  end

  private

  def authorization
    raise NotImplementedError, "Google Calendar authorization is not configured yet"
  end
end
