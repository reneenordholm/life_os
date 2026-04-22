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
    # Structured domain filters
    if lowered.include?("recipe")
      scope = scope.where(documents: { doc_type: "recipe" })
    elsif lowered.include?("grocery")
      scope = scope.where(documents: { doc_type: "grocery" })
    elsif lowered.include?("medical") || lowered.include?("doctor")
      scope = scope.where(documents: { doc_type: "medical" })
    elsif lowered.include?("trip") || lowered.include?("vacation")
      scope = scope.where(documents: { doc_type: "itinerary" })
    end
    # 🗓️ Metadata-based temporal filtering
    if lowered.include?("today")
      today = Date.today.to_s
      scope = scope.where(
        "documents.metadata ->> 'date' = ?",
        today
      )
    elsif lowered.include?("yesterday")
      yesterday = (Date.today - 1).to_s
      scope = scope.where(
        "documents.metadata ->> 'date' = ?",
        yesterday
      )
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

    puts "Context length: #{context.length}"
    puts "Chunks used: #{chunks.count}" 

    ask_llm(context)
  end

  private

  def ask_llm(context)
    today = Date.today

    weekday_map = (0..6).map do |i|
      d = today - i
      "#{d.strftime('%A')} was #{d.strftime('%B %-d, %Y')}"
    end.join("\n")

    response = EmbeddingService.client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: <<~SYSTEM
              You are a personal Life OS assistant with memory.

              Today's date is #{today.strftime('%B %-d, %Y')}.

              Recent calendar reference:
              #{weekday_map}

              Use this information to correctly interpret:
              - today
              - yesterday
              - weekday names (Sunday, Monday, etc.)

              Answer using the provided context.

              If the answer is not in the context, say you don't know.

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
