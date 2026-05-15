require "test_helper"

class TodayControllerTest < ActionDispatch::IntegrationTest
  test "renders today's daily log summary and content when present" do
    daily_log = Document.create!(
      title: "Today's Log",
      doc_type: "daily_log",
      metadata: {
        date: Date.current.iso8601
      },
      summary: "Today summary",
      content: "Today content"
    )

    get today_index_url

    assert_response :success
    assert_includes @response.body, daily_log.summary
    assert_includes @response.body, daily_log.content
  end

  test "does not render a daily log from another date when today's log is absent" do
    daily_log = Document.create!(
      title: "Yesterday's Log",
      doc_type: "daily_log",
      metadata: {
        date: 1.day.ago.to_date.iso8601
      },
      summary: "Yesterday summary",
      content: "Yesterday content"
    )

    get today_index_url

    assert_response :success
    assert_not_includes @response.body, daily_log.summary
    assert_not_includes @response.body, daily_log.content

    assert_includes @response.body, "No daily log yet."
  end
end
