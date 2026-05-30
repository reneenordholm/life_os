require "test_helper"

class TodayControllerTest < ActionDispatch::IntegrationTest
  test "renders today's daily log summary and content when present" do
    frozen_date = Date.new(2024, 1, 15)

    travel_to(frozen_date) do
      daily_log = Document.create!(
        title: "Today's Log",
        doc_type: "daily_log",
        metadata: {
          date: frozen_date.iso8601
        },
        summary: "Today summary",
        content: "Today content"
      )

      get root_url

      assert_response :success
      assert_includes @response.body, daily_log.summary
      assert_includes @response.body, daily_log.content
    end
  end

  test "does not render a daily log from another date when today's log is absent" do
    frozen_date = Date.new(2024, 1, 15)

    travel_to(frozen_date) do
      daily_log = Document.create!(
        title: "Yesterday's Log",
        doc_type: "daily_log",
        metadata: {
          date: frozen_date.yesterday.iso8601
        },
        summary: "Yesterday summary",
        content: "Yesterday content"
      )

      get root_url

      assert_response :success
      assert_not_includes @response.body, daily_log.summary
      assert_not_includes @response.body, daily_log.content

      assert_includes @response.body, "No daily log yet."
    end
  end

  test "renders daily log content with empty summary state when summary is missing" do
    frozen_date = Date.new(2024, 1, 15)

    travel_to(frozen_date) do
      daily_log = Document.create!(
        title: "Today Log Without Summary",
        doc_type: "daily_log",
        metadata: {
          date: frozen_date.iso8601
        },
        content: "Today content without summary",
        summary: nil
      )

      get root_url

      assert_response :success
      assert_includes @response.body, daily_log.content
      assert_includes @response.body, "No summary available."
      assert_not_includes @response.body, "No summary available because there is no daily log yet."
    end
  end

  test "renders today's calendar events" do
    frozen_date = Date.new(2024, 1, 15)

    travel_to(frozen_date) do
      event = CalendarEvent.create!(
        title: "Dentist Appointment",
        starts_at: Time.zone.local(2024, 1, 15, 9, 0),
        ends_at: Time.zone.local(2024, 1, 15, 10, 0),
        location: "Downtown"
      )

      get root_url

      assert_response :success
      assert_includes @response.body, event.title
      assert_includes @response.body, "9:00 AM"
      assert_includes @response.body, "10:00 AM"
      assert_includes @response.body, event.location
    end
  end

  test "renders empty calendar state when no events exist today" do
    frozen_date = Date.new(2024, 1, 15)

    travel_to(frozen_date) do
      CalendarEvent.create!(
        title: "Yesterday Event",
        starts_at: Time.zone.local(2024, 1, 14, 9, 0),
        ends_at: Time.zone.local(2024, 1, 14, 10, 0),
        location: "Elsewhere"
      )

      get root_url

      assert_response :success
      assert_includes @response.body, "No events today."
      assert_not_includes @response.body, "Yesterday Event"
      assert_not_includes @response.body, "Elsewhere"
    end
  end

  test "renders morning greeting" do
    travel_to Time.zone.local(2024, 1, 15, 8, 0) do
      get root_url

      assert_response :success
      assert_includes @response.body, "Good morning"
    end
  end

  test "renders afternoon greeting" do
    travel_to Time.zone.local(2024, 1, 15, 14, 0) do
      get root_url

      assert_response :success
      assert_includes @response.body, "Good afternoon"
    end
  end

  test "renders evening greeting" do
    travel_to Time.zone.local(2024, 1, 15, 20, 0) do
      get root_url

      assert_response :success
      assert_includes @response.body, "Good evening"
    end
  end

  test "syncs calendar and redirects to dashboard" do
    frozen_time = Time.zone.local(2024, 1, 15, 9, 30)

    travel_to(frozen_time) do
      original_call_method = CalendarEventSyncService.method(:call)
      called_with = nil

      begin
        CalendarEventSyncService.define_singleton_method(:call) do |start_time:, end_time:, **_kwargs|
          called_with = { start_time: start_time, end_time: end_time }
          []
        end

        post sync_calendar_path

        assert_redirected_to root_path
        follow_redirect!
        assert_response :success
        assert_includes @response.body, "Calendar synced successfully."

        assert_equal frozen_time.beginning_of_day, called_with[:start_time]
        assert_equal frozen_time.end_of_day, called_with[:end_time]
      ensure
        CalendarEventSyncService.define_singleton_method(:call, original_call_method)
      end
    end
  end
end
