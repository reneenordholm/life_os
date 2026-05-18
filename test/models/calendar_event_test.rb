require "test_helper"

class CalendarEventTest < ActiveSupport::TestCase
  test "title and starts_at must be present" do
    event = CalendarEvent.new

    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "ends_at can be nil" do
    starts_at = Time.current
    event = CalendarEvent.new(title: "Planning", starts_at: starts_at, ends_at: nil)

    assert event.valid?
    assert_empty event.errors[:ends_at]
  end

  test "ends_at can equal starts_at" do
    starts_at = Time.current
    event = CalendarEvent.new(title: "Planning", starts_at: starts_at, ends_at: starts_at)

    assert event.valid?
    assert_empty event.errors[:ends_at]
  end

  test "ends_at cannot be earlier than starts_at" do
    starts_at = Time.current

    event = CalendarEvent.new(
      title: "Planning",
      starts_at: starts_at,
      ends_at: starts_at - 1.minute
    )

    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be greater than or equal to starts_at"
  end
end
