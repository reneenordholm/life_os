require "test_helper"

class DailyLogServiceTest < ActiveSupport::TestCase
  test "creates daily log for date" do
    date = Date.new(2026, 5, 30)

    doc = DailyLogService.create_or_update_for_date(
      date,
      "First log"
    )

    assert_equal "daily_log", doc.doc_type
    assert_equal "📓 Daily Log — #{date}", doc.title
    assert_equal "First log", doc.content
    assert_equal date.to_s, doc.metadata["date"]
  end

  test "updates existing daily log for date" do
    date = Date.new(2026, 5, 30)

    first_doc =
      DailyLogService.create_or_update_for_date(
        date,
        "Original log"
      )

    updated_doc =
      DailyLogService.create_or_update_for_date(
        date,
        "Updated log"
      )

    assert_equal first_doc.id, updated_doc.id
    assert_equal "Updated log", updated_doc.content

    assert_equal 1,
      Document.where(
        doc_type: "daily_log",
        title: "📓 Daily Log — #{date}"
      ).count
  end
end
