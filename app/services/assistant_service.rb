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

    # Apply structured doc_type filters first.
    # If one is applied, skip weekday filtering to avoid false matches
    # like "Sunday sauce recipe".
    structured_filter_applied = false

    if lowered.include?("recipe")
      scope = scope.where(documents: { doc_type: "recipe" })
      structured_filter_applied = true
    elsif lowered.include?("grocery")
      scope = scope.where(documents: { doc_type: "grocery" })
      structured_filter_applied = true
    elsif lowered.include?("medical") || lowered.include?("doctor")
      scope = scope.where(documents: { doc_type: "medical" })
      structured_filter_applied = true
    elsif lowered.include?("trip") || lowered.include?("vacation")
      scope = scope.where(documents: { doc_type: "itinerary" })
      structured_filter_applied = true
    end

    parsed_time = TimeParser.parse(@question)

    if parsed_time
      case parsed_time[:type]
      when :date
        scope = scope.where(
          "documents.metadata ->> 'date' = ?",
          parsed_time[:value].to_s
        )
      when :range
        scope = scope.where(
          "CAST(documents.metadata ->> 'date' AS date) BETWEEN ? AND ?",
          parsed_time[:value].first,
          parsed_time[:value].last
        )
      end
    else
      if lowered.include?("today")
        scope = scope.where(
          "documents.metadata ->> 'date' = ?",
          Date.today.to_s
        )
      elsif lowered.include?("yesterday")
        scope = scope.where(
          "documents.metadata ->> 'date' = ?",
          (Date.today - 1).to_s
        )
      elsif !structured_filter_applied
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

        metadata_keys = %w[
          date
          weekday
          category
          person
          species
          condition
          last_curve_date
        ]

        filtered_metadata = document.metadata&.slice(*metadata_keys).presence
        metadata_line = filtered_metadata ? filtered_metadata.to_json : nil

        [
          "Source: #{document.title}",
          "Document type: #{document.doc_type}",
          ("Metadata: #{metadata_line}" if metadata_line),
          "",
          chunk.content
        ].compact.join("\n")
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
