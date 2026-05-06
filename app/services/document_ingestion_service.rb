class DocumentIngestionService
  def initialize(document)
    @document = document
  end

  def call
    chunks_with_embeddings = Chunker.call(@document.content).map do |chunk|
      {
        content: chunk,
        embedding: EmbeddingService.embed(chunk)
      }
    end

    # Remove old chunks and entity links before re-ingesting
    ActiveRecord::Base.transaction do
      @document.document_chunks.delete_all
      @document.document_entities.delete_all

      chunks_with_embeddings.each do |attrs|
        @document.document_chunks.create!(attrs)
      end

      EntityExtractionService.new(@document).call
    end
  end
end
