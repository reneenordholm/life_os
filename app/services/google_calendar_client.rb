require "google/apis/calendar_v3"
require "signet/oauth_2/client"

class GoogleCalendarClient
  Calendar = Google::Apis::CalendarV3

  def initialize(
    calendar_id: "primary",
    service: Calendar::CalendarService.new,
    authorization: nil,
    env: ENV
  )
    @calendar_id = calendar_id
    @service = service
    @authorization = authorization
    @env = env
  end

  def events_for_range(start_time:, end_time:)
    @service.authorization ||= @authorization || authorization

    events = []
    page_token = nil

    loop do
      response = @service.list_events(
        @calendar_id,
        single_events: true,
        order_by: "startTime",
        time_min: start_time.iso8601,
        time_max: end_time.iso8601,
        page_token: page_token
      )

      events.concat(response.items || [])

      page_token = response.next_page_token
      break if page_token.blank?
    end

    events
  end

  private

  def authorization
    validate_google_credentials!

    client = Signet::OAuth2::Client.new(
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id: @env.fetch("GOOGLE_CLIENT_ID").strip,
      client_secret: @env.fetch("GOOGLE_CLIENT_SECRET").strip,
      refresh_token: @env.fetch("GOOGLE_REFRESH_TOKEN").strip
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

    missing_env_vars = required_env_vars.select do |env_var|
      @env[env_var].to_s.strip.empty?
    end
    return if missing_env_vars.empty?

    raise ArgumentError,
          "Google Calendar credentials are not configured. " \
          "Set the following environment variables: #{missing_env_vars.join(', ')}"
  end
end
