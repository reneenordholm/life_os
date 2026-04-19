class DocumentIngestionService
  def initialize(document)
    @document = document
  end

  def call
    chunks = Chunker.call(@document.content)

    chunks.each do |chunk|
      embedding = EmbeddingService.embed(chunk)

      @document.document_chunks.create!(
        content: chunk,
        embedding: embedding
      )
    end
  end
end