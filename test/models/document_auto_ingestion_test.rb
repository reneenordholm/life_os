require "test_helper"

class DocumentAutoIngestionTest < ActiveSupport::TestCase
  test "creates chunks and entities when document is created" do
    document = Document.create!(
      title: "Auto Ingestion Test",
      doc_type: "note",
      content: "Marley is here"
    )

    assert_equal 1, document.document_chunks.count
    assert_equal [ "Marley" ], document.entities.pluck(:name)
  end

  test "rebuilds chunks and replaces stale entity links when content changes" do
    document = Document.create!(
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
    document = Document.create!(
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
    document = Document.create!(
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
