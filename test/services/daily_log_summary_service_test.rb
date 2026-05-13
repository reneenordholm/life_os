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

  test "persists generated summary" do
    fake_client = Object.new
    fake_client.define_singleton_method(:chat) do |parameters:|
      { "choices" => [ { "message" => { "content" => "Cached daily summary" } } ] }
    end

    original_client_method = EmbeddingService.method(:client)
    EmbeddingService.define_singleton_method(:client) { fake_client }

    document = create_document!(
      title: "Summary Cache Test",
      doc_type: "daily_log",
      metadata: { date: "2026-05-05" },
      content: "Original daily log content"
    )

    document.reload
    assert_equal "Cached daily summary", document.summary
  ensure
    EmbeddingService.define_singleton_method(:client, original_client_method)
  end

  test "reuses cached summary without calling LLM" do
    document = create_document!(
      title: "Cached Summary Reuse Test",
      doc_type: "daily_log",
      metadata: { date: "2026-05-05" },
      content: "Original daily log content",
      summary: "Existing cached summary"
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:chat) do |parameters:|
      raise "LLM should not be called"
    end

    original_client_method = EmbeddingService.method(:client)
    EmbeddingService.define_singleton_method(:client) { fake_client }

    DailyLogSummaryService.call(document)

    document.reload
    assert_equal "Existing cached summary", document.summary
  ensure
    EmbeddingService.define_singleton_method(:client, original_client_method)
  end
end
