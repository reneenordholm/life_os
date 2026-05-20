require "google/apis/calendar_v3"
require "signet/oauth_2/client"

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
    client = Signet::OAuth2::Client.new(
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      refresh_token: ENV.fetch("GOOGLE_REFRESH_TOKEN")
    )

    client.fetch_access_token!

    client
  end
end
