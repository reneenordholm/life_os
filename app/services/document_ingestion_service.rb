class DocumentIngestionService
  def initialize(document)
    @document = document
  end

  def call
    # Remove old chunks and entity links before re-ingesting
    @document.document_chunks.delete_all
    @document.document_entities.delete_all

    chunks = Chunker.call(@document.content)

    chunks.each do |chunk|
      embedding = EmbeddingService.embed(chunk)

      @document.document_chunks.create!(
        content: chunk,
        embedding: embedding
      )
    end

    EntityExtractionService.new(@document).call
  end
end
