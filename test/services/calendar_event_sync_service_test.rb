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
      end: EventDateTime.new(date: event_date + 1.day),
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
    assert_equal (event_date + 1.day).in_time_zone - 1.second, calendar_event.ends_at
    assert_equal "Lake Union", calendar_event.location
  end

  test "removes stale synced events within sync window" do
    start_time = Time.zone.local(2026, 5, 20, 0, 0)
    end_time = Time.zone.local(2026, 5, 20, 23, 59, 59)

    stale_event = CalendarEvent.create!(
      source: "google",
      external_id: "stale-google-event",
      title: "Deleted Google Event",
      starts_at: Time.zone.local(2026, 5, 20, 9, 0),
      ends_at: Time.zone.local(2026, 5, 20, 10, 0)
    )

    out_of_window_event = CalendarEvent.create!(
      source: "google",
      external_id: "out-of-window-google-event",
      title: "Tomorrow Google Event",
      starts_at: Time.zone.local(2026, 5, 21, 9, 0),
      ends_at: Time.zone.local(2026, 5, 21, 10, 0)
    )

    manual_event = CalendarEvent.create!(
      source: "manual",
      external_id: "manual-event",
      title: "Manual Event",
      starts_at: Time.zone.local(2026, 5, 20, 12, 0),
      ends_at: Time.zone.local(2026, 5, 20, 13, 0)
    )

    google_event = GoogleEvent.new(
      id: "current-google-event",
      summary: "Current Google Event",
      start: EventDateTime.new(date_time: Time.zone.local(2026, 5, 20, 14, 0)),
      end: EventDateTime.new(date_time: Time.zone.local(2026, 5, 20, 15, 0)),
      location: "Office"
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:events_for_range) do |start_time:, end_time:|
      [ google_event ]
    end

    CalendarEventSyncService.call(
      start_time: start_time,
      end_time: end_time,
      client: fake_client
    )

    assert_nil CalendarEvent.find_by(id: stale_event.id)
    assert CalendarEvent.exists?(id: out_of_window_event.id)
    assert CalendarEvent.exists?(id: manual_event.id)
    assert CalendarEvent.exists?(source: "google", external_id: "current-google-event")
  end
end
