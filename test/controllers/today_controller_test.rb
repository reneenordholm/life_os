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

      get today_index_url

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

      get today_index_url

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

      get today_index_url

      assert_response :success
      assert_includes @response.body, daily_log.content
      assert_includes @response.body, "No summary available."
      assert_not_includes @response.body, "No summary available because there is no daily log yet."
    end
  end
end
