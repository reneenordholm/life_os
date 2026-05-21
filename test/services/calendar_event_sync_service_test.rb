require "test_helper"

class CalendarEventSyncServiceTest < ActiveSupport::TestCase
  EventDateTime = Struct.new(:date_time, :date, keyword_init: true)
  GoogleEvent = Struct.new(:id, :summary, :start, :end, :location, keyword_init: true)

  test "syncs Google calendar events into CalendarEvent records" do
    start_time = Time.zone.local(2026, 5, 20, 9, 0)
    end_time = Time.zone.local(2026, 5, 20, 10, 0)

    google_event = GoogleEvent.new(
      id: "google-event-1",
      summary: "Doctor Appointment",
      start: EventDateTime.new(date_time: start_time),
      end: EventDateTime.new(date_time: end_time),
      location: "Downtown"
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:events_for_range) do |start_time:, end_time:|
      [ google_event ]
    end

    synced_events = CalendarEventSyncService.call(
      start_time: start_time.beginning_of_day,
      end_time: start_time.end_of_day,
      client: fake_client
    )

    calendar_event = CalendarEvent.find_by!(
      source: "google",
      external_id: "google-event-1"
    )

    assert_equal [ calendar_event ], synced_events
    assert_equal "Doctor Appointment", calendar_event.title
    assert_equal start_time, calendar_event.starts_at
    assert_equal end_time, calendar_event.ends_at
    assert_equal "Downtown", calendar_event.location
  end

  test "updates existing synced event" do
    existing_event = CalendarEvent.create!(
      source: "google",
      external_id: "google-event-1",
      title: "Old Title",
      starts_at: Time.zone.local(2026, 5, 20, 8, 0)
    )

    google_event = GoogleEvent.new(
      id: "google-event-1",
      summary: "Updated Title",
      start: EventDateTime.new(date_time: Time.zone.local(2026, 5, 20, 9, 0)),
      end: EventDateTime.new(date_time: Time.zone.local(2026, 5, 20, 10, 0)),
      location: "Updated Location"
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:events_for_range) do |start_time:, end_time:|
      [ google_event ]
    end

    CalendarEventSyncService.call(
      start_time: Time.zone.local(2026, 5, 20).beginning_of_day,
      end_time: Time.zone.local(2026, 5, 20).end_of_day,
      client: fake_client
    )

    existing_event.reload

    assert_equal "Updated Title", existing_event.title
    assert_equal "Updated Location", existing_event.location
    assert_equal Time.zone.local(2026, 5, 20, 9, 0), existing_event.starts_at
  end

  test "uses fallback title when Google event summary is blank" do
    google_event = GoogleEvent.new(
      id: "google-event-blank-title",
      summary: "",
      start: EventDateTime.new(date_time: Time.zone.local(2026, 5, 20, 9, 0)),
      end: EventDateTime.new(date_time: Time.zone.local(2026, 5, 20, 10, 0)),
      location: nil
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:events_for_range) do |start_time:, end_time:|
      [ google_event ]
    end

    CalendarEventSyncService.call(
      start_time: Time.zone.local(2026, 5, 20).beginning_of_day,
      end_time: Time.zone.local(2026, 5, 20).end_of_day,
      client: fake_client
    )

    calendar_event = CalendarEvent.find_by!(
      source: "google",
      external_id: "google-event-blank-title"
    )

    assert_equal "Untitled event", calendar_event.title
  end

  test "syncs all-day Google calendar events" do
    event_date = Date.new(2026, 5, 21)

    google_event = GoogleEvent.new(
      id: "google-all-day-event",
      summary: "Boat Day",
      start: EventDateTime.new(date: event_date),
      end: EventDateTime.new(date: event_date),
      location: "Lake Union"
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:events_for_range) do |start_time:, end_time:|
      [ google_event ]
    end

    CalendarEventSyncService.call(
      start_time: event_date.beginning_of_day,
      end_time: event_date.end_of_day,
      client: fake_client
    )

    calendar_event = CalendarEvent.find_by!(
      source: "google",
      external_id: "google-all-day-event"
    )

    assert_equal "Boat Day", calendar_event.title
    assert_equal event_date.in_time_zone, calendar_event.starts_at
    assert_equal event_date.in_time_zone, calendar_event.ends_at
    assert_equal "Lake Union", calendar_event.location
  end
end
