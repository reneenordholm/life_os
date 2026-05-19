require "test_helper"

class GoogleCalendarClientTest < ActiveSupport::TestCase
  test "raises when authorization is not configured" do
    assert_raises(NotImplementedError) do
      GoogleCalendarClient.new.events_for_range(
        start_time: Time.current.beginning_of_day,
        end_time: Time.current.end_of_day
      )
    end
  end

  test "fetches events for a time range" do
    start_time = Time.zone.local(2026, 5, 18, 9, 0)
    end_time = Time.zone.local(2026, 5, 18, 17, 0)

    event = Object.new

    response = Object.new
    response.define_singleton_method(:items) { [ event ] }

    captured_calendar_id = nil
    captured_options = nil

    fake_service = Object.new
    fake_service.define_singleton_method(:authorization) { nil }
    fake_service.define_singleton_method(:authorization=) { |_authorization| }

    fake_service.define_singleton_method(:list_events) do |calendar_id, **options|
      captured_calendar_id = calendar_id
      captured_options = options
      response
    end

    client = GoogleCalendarClient.new(
      service: fake_service,
      authorization: "fake-authorization"
    )

    assert_equal [ event ], client.events_for_range(
      start_time: start_time,
      end_time: end_time
    )

    assert_equal "primary", captured_calendar_id
    assert_equal true, captured_options[:single_events]
    assert_equal "startTime", captured_options[:order_by]
    assert_equal start_time.iso8601, captured_options[:time_min]
    assert_equal end_time.iso8601, captured_options[:time_max]
  end
end
