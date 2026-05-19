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
end
