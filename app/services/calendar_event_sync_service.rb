class CalendarEventSyncService
  SOURCE = "google"

  def self.call(start_time:, end_time:, client: GoogleCalendarClient.new)
    new(start_time: start_time, end_time: end_time, client: client).call
  end

  def initialize(start_time:, end_time:, client:)
    @start_time = start_time
    @end_time = end_time
    @client = client
  end

  def call
    events = @client.events_for_range(
      start_time: @start_time,
      end_time: @end_time
    )

    events.map do |google_event|
      sync_event(google_event)
    end
  end

  private

  def sync_event(google_event)
    calendar_event = CalendarEvent.find_or_initialize_by(
      source: SOURCE,
      external_id: google_event.id
    )

    calendar_event.assign_attributes(
      title: google_event.summary.presence || "Untitled event",
      starts_at: event_time(google_event.start),
      ends_at: event_time(google_event.end),
      location: google_event.location
    )

    calendar_event.save!
    calendar_event
  end

  def event_time(event_date_time)
    return event_date_time.date_time if event_date_time.date_time.present?
    return event_date_time.date.to_time if event_date_time.date.present?

    nil
  end
end
