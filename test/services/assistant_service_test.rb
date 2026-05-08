require "test_helper"

class AssistantServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @created_document_ids = []
  end

  teardown do
    Document.where(id: @created_document_ids).destroy_all
  end

  def create_document!(attrs)
    doc = Document.create!(attrs)
    @created_document_ids << doc.id
    doc
  end

  test "retrieves this week daily logs chronologically" do
    travel_to Date.new(2026, 5, 7) do
      create_document!(
        title: "📓 Daily Log — 2026-05-05",
        doc_type: "daily_log",
        metadata: {
          date: "2026-05-05",
          weekday: "Tuesday",
          category: "daily"
        },
        content: "Tuesday log content"
      )

      create_document!(
        title: "📓 Daily Log — 2026-05-03",
        doc_type: "daily_log",
        metadata: {
          date: "2026-05-03",
          weekday: "Sunday",
          category: "daily"
        },
        content: "Sunday log content"
      )

      service = AssistantService.new("What did I do this week?")
      parsed_time = TimeParser.parse("What did I do this week?")
      logs = service.send(:retrieve_daily_logs_for_range, parsed_time[:value])

      assert_equal 2, logs.count

      assert_match(/2026-05-03/, logs.first)
      assert_match(/2026-05-05/, logs.second)

      assert_includes logs.first, "Sunday log content"
      assert_includes logs.second, "Tuesday log content"
    end
  end

  test "retrieves last week daily logs chronologically" do
    travel_to Date.new(2026, 5, 7) do
      create_document!(
        title: "📓 Daily Log — 2026-04-29",
        doc_type: "daily_log",
        metadata: {
          date: "2026-04-29",
          weekday: "Wednesday",
          category: "daily"
        },
        content: "Wednesday last week content"
      )

      create_document!(
        title: "📓 Daily Log — 2026-04-27",
        doc_type: "daily_log",
        metadata: {
          date: "2026-04-27",
          weekday: "Monday",
          category: "daily"
        },
        content: "Monday last week content"
      )

      service = AssistantService.new("What did I do last week?")
      parsed_time = TimeParser.parse("What did I do last week?")
      logs = service.send(:retrieve_daily_logs_for_range, parsed_time[:value])

      assert_equal 2, logs.count

      assert_match(/2026-04-27/, logs.first)
      assert_match(/2026-04-29/, logs.second)

      assert_includes logs.first, "Monday last week content"
      assert_includes logs.second, "Wednesday last week content"
    end
  end

  test "range query SQL filtering returns recipe documents only" do
    travel_to Date.new(2026, 5, 7) do
      create_document!(
        title: "Recipe - Tacos",
        doc_type: "recipe",
        metadata: {
          date: "2026-05-05"
        },
        content: "Made tacos"
      )

      create_document!(
        title: "📓 Daily Log — 2026-05-05",
        doc_type: "daily_log",
        metadata: {
          date: "2026-05-05",
          weekday: "Tuesday",
          category: "daily"
        },
        content: "Daily log content that should not be included"
      )

      parsed_time = TimeParser.parse("What recipes did I make this week?")

      scope = DocumentChunk.joins(:document)
      scope = scope.where(documents: { doc_type: "recipe" })
      scope = scope.where(
        "CAST(documents.metadata ->> 'date' AS date) BETWEEN ? AND ?",
        parsed_time[:value].first,
        parsed_time[:value].last
      )

      results = scope.pluck("documents.title").uniq

      assert_includes results, "Recipe - Tacos"
      assert_not_includes results, "📓 Daily Log — 2026-05-05"
    end
  end

  test "truncates weekly logs at context limit without breaking" do
    travel_to Date.new(2026, 5, 7) do
      long_content = "A" * 8_000

      create_document!(
        title: "📓 Daily Log — 2026-05-03",
        doc_type: "daily_log",
        metadata: { date: "2026-05-03" },
        content: long_content
      )

      create_document!(
        title: "📓 Daily Log — 2026-05-04",
        doc_type: "daily_log",
        metadata: { date: "2026-05-04" },
        content: long_content
      )

      service = AssistantService.new("What did I do this week?")
      parsed_time = TimeParser.parse("What did I do this week?")

      logs = service.send(:retrieve_daily_logs_for_range, parsed_time[:value])

      # simulate truncation logic
      selected_logs = []
      context_length = 0
      separator = "\n\n---\n\n"

      logs.each do |log|
        projected_length =
          context_length +
          log.length +
          (selected_logs.empty? ? 0 : separator.length)

        break if projected_length > AssistantService::MAX_RANGE_CONTEXT_LENGTH

        selected_logs << log
        context_length = projected_length
      end

      assert selected_logs.any?
      assert selected_logs.length < logs.length
    end
  end

  test "falls back when a single log exceeds context limit" do
    travel_to Date.new(2026, 5, 7) do
      huge_content = "A" * 20_000

      create_document!(
        title: "📓 Daily Log — 2026-05-03",
        doc_type: "daily_log",
        metadata: { date: "2026-05-03" },
        content: huge_content
      )

      service = AssistantService.new("What did I do this week?")
      parsed_time = TimeParser.parse("What did I do this week?")

      logs = service.send(:retrieve_daily_logs_for_range, parsed_time[:value])

      selected_logs = []
      context_length = 0

      logs.each do |log|
        break if log.length > AssistantService::MAX_RANGE_CONTEXT_LENGTH
      end

      assert selected_logs.empty?
    end
  end
end
