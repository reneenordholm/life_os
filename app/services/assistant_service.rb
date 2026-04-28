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

    matched_entity = Entity.find_each.find do |entity|
      lowered.include?(entity.name.downcase)
    end

    if matched_entity
      scope = scope
        .joins(document: :document_entities)
        .where(document_entities: { entity_id: matched_entity.id })
    end

    # Structured domain filters
    domain_filter_applied = false

    if lowered.include?("recipe")
      scope = scope.where(documents: { doc_type: "recipe" })
      domain_filter_applied = true
    elsif lowered.include?("grocery")
      scope = scope.where(documents: { doc_type: "grocery" })
      domain_filter_applied = true
    elsif lowered.include?("medical") || lowered.include?("doctor")
      scope = scope.where(documents: { doc_type: "medical" })
      domain_filter_applied = true
    elsif lowered.include?("trip") || lowered.include?("vacation")
      scope = scope.where(documents: { doc_type: "itinerary" })
      domain_filter_applied = true
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

    # weekday-aware metadata retrieval — only applied for temporal/daily-log queries,
    # not when a structured domain filter (recipe, grocery, etc.) is already in effect.
    unless domain_filter_applied
      weekdays = %w[
        Sunday
        Monday
        Tuesday
        Wednesday
        Thursday
        Friday
        Saturday
      ]

      matched_weekday = weekdays.find do |weekday|
        lowered.include?(weekday.downcase)
      end

      if matched_weekday
        scope = scope.where(
          "documents.metadata ->> 'weekday' = ?",
          matched_weekday
        )
      end
    end

    chunks = retrieve_chunks(scope, embedding)

    if chunks.empty? && matched_entity
      fallback_scope = DocumentChunk.joins(:document)
      chunks = retrieve_chunks(fallback_scope, embedding)
    end

    context = chunks.join("\n\n---\n\n")

    puts "Matched entity: #{matched_entity&.name || 'none'}"
    puts "Context length: #{context.length}"
    puts "Chunks used: #{chunks.count}"

    ask_llm(context)
  end

  private

  def retrieve_chunks(scope, embedding)
    scope
      .includes(:document)
      .nearest_neighbors(
        :embedding,
        embedding,
        distance: "cosine"
      )
      .limit(5)
      .map do |chunk|
        document = chunk.document

        <<~TEXT
          Source: #{document.title}
          Document type: #{document.doc_type}
          Metadata: #{document.metadata}

          #{chunk.content}
        TEXT
    end
  end

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
