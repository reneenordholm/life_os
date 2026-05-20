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
    validate_google_credentials!

    client = Signet::OAuth2::Client.new(
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      refresh_token: ENV["GOOGLE_REFRESH_TOKEN"]
    )

    client.fetch_access_token!

    client
  end

  def validate_google_credentials!
    required_env_vars = %w[
      GOOGLE_CLIENT_ID
      GOOGLE_CLIENT_SECRET
      GOOGLE_REFRESH_TOKEN
    ]

    missing_env_vars = required_env_vars.select { |env_var| ENV[env_var].to_s.strip.empty? }
    return if missing_env_vars.empty?

    raise NotImplementedError,
          "Google Calendar credentials are not configured. " \
          "Set the following environment variables: #{missing_env_vars.join(', ')}"
  end
end
