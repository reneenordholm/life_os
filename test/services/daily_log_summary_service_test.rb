require "test_helper"

class DailyLogSummaryServiceTest < ActiveSupport::TestCase
  setup do
    @created_document_ids = []
  end

  teardown do
    Document.where(id: @created_document_ids).destroy_all
  end

  def create_document!(attrs)
    document = Document.create!(attrs)
    @created_document_ids << document.id
    document
  end

  def with_stubbed_llm_client(fake_client)
    original_client_method = EmbeddingService.method(:client)
    EmbeddingService.define_singleton_method(:client) { fake_client }

    yield
  ensure
    EmbeddingService.define_singleton_method(:client, original_client_method)
  end

  test "persists generated summary" do
    fake_client = Object.new
    fake_client.define_singleton_method(:chat) do |parameters:|
      { "choices" => [ { "message" => { "content" => "Cached daily summary" } } ] }
    end

    document = create_document!(
      title: "Summary Cache Test",
      doc_type: "daily_log",
      metadata: { date: "2026-05-05" },
      content: "Original daily log content"
    )

    with_stubbed_llm_client(fake_client) do
      DailyLogSummaryService.call(document)
    end

    document.reload
    assert_equal "Cached daily summary", document.summary
  end

  test "reuses cached summary without calling LLM" do
    document = create_document!(
      title: "Cached Summary Reuse Test",
      doc_type: "daily_log",
      metadata: { date: "2026-05-05" },
      content: "Original daily log content",
      summary: "Existing cached summary"
    )

    fake_client = Object.new.tap do |c|
      c.define_singleton_method(:chat) { raise "LLM should not be called" }
    end

    with_stubbed_llm_client(fake_client) do
      DailyLogSummaryService.call(document)
    end

    document.reload
    assert_equal "Existing cached summary", document.summary
  end

  test "daily_log gets summary when summary service runs" do
    fake_client = Object.new
    fake_client.define_singleton_method(:chat) do |parameters:|
      { "choices" => [ { "message" => { "content" => "Generated summary" } } ] }
    end

    document = create_document!(
      title: "Daily Log Ingestion Test",
      doc_type: "daily_log",
      metadata: { date: "2026-05-05" },
      content: "Did some stuff"
    )

    with_stubbed_llm_client(fake_client) do
      DailyLogSummaryService.call(document)
    end

    document.reload
    assert_equal "Generated summary", document.summary
  end

  test "non-daily_log does not generate summary when summary service runs" do
    fake_client = Object.new
    fake_client.define_singleton_method(:chat) do |parameters:|
      raise "LLM should not be called"
    end

    document = create_document!(
      title: "Recipe Test",
      doc_type: "recipe",
      metadata: {},
      content: "Some recipe content"
    )

    with_stubbed_llm_client(fake_client) do
      DailyLogSummaryService.call(document)
    end

    document.reload
    assert_nil document.summary
  end
end
