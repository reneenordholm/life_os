require "test_helper"

class DocumentAutoIngestionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

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

  test "creates chunks and entities when document is created" do
    document = create_document!(
      title: "Auto Ingestion Test",
      doc_type: "note",
      content: "Marley is here"
    )

    assert_equal 1, document.document_chunks.count
    assert_equal [ "Marley" ], document.entities.pluck(:name)
  end

  test "rebuilds chunks and replaces stale entity links when content changes" do
    document = create_document!(
      title: "Auto Update Test",
      doc_type: "note",
      content: "Marley is here"
    )

    assert_equal [ "Marley" ], document.entities.pluck(:name)

    document.update!(content: "Mom is here")
    document.reload

    assert_equal 1, document.document_chunks.count
    assert_equal [ "Mom" ], document.entities.pluck(:name)
  end

  test "does not ingest when only title changes" do
    document = create_document!(
      title: "Title Test",
      doc_type: "note",
      content: "Marley is here"
    )

    original_chunk_ids = document.document_chunks.pluck(:id)

    document.update!(title: "Updated Title")
    document.reload

    assert_equal original_chunk_ids, document.document_chunks.pluck(:id)
  end

  test "clears chunks and entities when content is emptied" do
    document = create_document!(
      title: "Clear Test",
      doc_type: "note",
      content: "Marley is here"
    )

    assert_equal [ "Marley" ], document.entities.pluck(:name)

    document.update!(content: "")
    document.reload

    assert_equal 0, document.document_chunks.count
    assert_equal [], document.entities.pluck(:name)
  end
end
