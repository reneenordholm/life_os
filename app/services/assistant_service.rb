# app/services/assistant_service.rb

class AssistantService
  def initialize(question)
    @question = question
  end

  def call
    embedding = EmbeddingService.embed(@question)

    scope = DocumentChunk.joins(:document)

    # Soft filtering for highly structured data like recipes, grocery lists, and medical notes.
    lowered = @question.downcase

    if lowered.include?("recipe")
      scope = scope.where(documents: { doc_type: "recipe" })
    elsif lowered.include?("grocery")
      scope = scope.where(documents: { doc_type: "grocery" })
    elsif lowered.include?("medical") || lowered.include?("doctor")
      scope = scope.where(documents: { doc_type: "medical" })
    elsif lowered.include?("trip") || lowered.include?("vacation")
      scope = scope.where(documents: { doc_type: "itinerary" })
    end

    chunks = scope
      .nearest_neighbors(
        :embedding,
        embedding,
        distance: "cosine"
      )
      .limit(5)
      .map(&:content)

    context = chunks.join("\n\n---\n\n")

    ask_llm(context)
  end

  private

  def ask_llm(context)
    response = EmbeddingService.client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: <<~SYSTEM
              You are a personal Life OS assistant.

              Answer using the provided context.

              If the answer is not in the context,
              say you don't know.

              Context:
              #{context}
            SYSTEM
          },
          {
            role: "user",
            content: @question
          }
        ]
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
