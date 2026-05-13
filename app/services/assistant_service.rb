class AssistantService
  MAX_RANGE_CONTEXT_LENGTH = 12_000
  LLM_MODEL = "gpt-4o-mini"

  def initialize(question)
    @question = question
  end

  def call
    scope = DocumentChunk.joins(:document)

    # Soft filtering for highly structured data like recipes, grocery lists, and medical notes.
    lowered = @question.downcase

    matched_entity = entities.detect do |entity|
      pattern = /\b#{Regexp.escape(entity.name.downcase)}\b/
      lowered.match?(pattern)
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
        range_start = parsed_time[:value].begin
        range_end = parsed_time[:value].end

        if !structured_filter_applied
          daily_log_documents = retrieve_daily_logs_for_range(
            parsed_time[:value],
            entity: matched_entity
          ).to_a

          selected_documents = []
          context_length = 0
          separator = "\n\n---\n\n"

          daily_log_documents.each do |document|
            estimated_length = (document.summary.presence || document.content).to_s.length

            projected_length =
              context_length +
              estimated_length +
              (selected_documents.empty? ? 0 : separator.length)

            break if projected_length > MAX_RANGE_CONTEXT_LENGTH

            selected_documents << document
            context_length = projected_length
          end

          context_truncated = selected_documents.count < daily_log_documents.count

          if selected_documents.any?
            daily_summaries = []
            summary_context_length = 0
            context_truncated = selected_documents.count < daily_log_documents.count

            selected_documents.each do |document|
              summary = summarize_daily_log(document)
              separator_length = daily_summaries.empty? ? 0 : separator.length

              projected_length =
                summary_context_length +
                summary.length +
                separator_length

              if projected_length > MAX_RANGE_CONTEXT_LENGTH
                context_truncated = true
                break
              end

              daily_summaries << summary
              summary_context_length = projected_length
            end

            if daily_summaries.any?
              context = daily_summaries.join(separator)

              if context_truncated
                truncation_note =
                  "\n\n---\n\nNote: Additional daily logs existed in this date range but were omitted due to context length limits."

                if context.length + truncation_note.length <= MAX_RANGE_CONTEXT_LENGTH
                  context += truncation_note
                end
              end

              if Rails.env.development?
                Rails.logger.debug(
                  "AssistantService | entity=#{matched_entity&.name || 'none'} " \
                  "context_length=#{context.length} logs=#{daily_summaries.count} " \
                  "truncated=#{context_truncated}"
                )
              end

              return ask_llm(context)
            end
          end
        end

        scope = scope.where(
          "CAST(documents.metadata ->> 'date' AS date) BETWEEN ? AND ?",
          range_start,
          range_end
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

    embedding = EmbeddingService.embed(@question)
    chunks = retrieve_chunks(scope, embedding)

    if chunks.empty? && matched_entity
      fallback_scope = DocumentChunk.joins(:document)
      chunks = retrieve_chunks(fallback_scope, embedding)
    end

    context = chunks.join("\n\n---\n\n")

    if Rails.env.development?
      Rails.logger.debug(
        "AssistantService | entity=#{matched_entity&.name || 'none'} " \
        "context_length=#{context.length} chunks=#{chunks.count}"
      )
    end

    ask_llm(context)
  end

  private

  def entities
    @entities ||= Entity.all
  end

  def retrieve_daily_logs_for_range(date_range, entity: nil)
    scope = Document
      .where(doc_type: "daily_log")
      .where(
        "CAST(metadata ->> 'date' AS date) BETWEEN ? AND ?",
        date_range.begin,
        date_range.end
      )

    if entity
      scope = scope
        .joins(:document_entities)
        .where(document_entities: { entity_id: entity.id })
        .group("documents.id")
    end

    scope.order(Arel.sql("CAST(metadata ->> 'date' AS date) ASC"))
  end

  def summarize_daily_log(document)
    return format_daily_summary(document, document.summary) if document.summary.present?

    log = <<~LOG
      Source: #{document.title}
      Metadata: #{document.metadata.slice("date", "weekday", "category").to_json}

      #{document.content}
    LOG

    response = EmbeddingService.client.chat(
      parameters: {
        model: LLM_MODEL,
        messages: [
          {
            role: "system",
            content: <<~SYSTEM
              Summarize this daily log into concise bullets.

              Preserve:
              - date
              - work
              - activities
              - projects
              - meals
              - notes

              Omit categories that are not present.

              Use only the provided log.
            SYSTEM
          },
          {
            role: "user",
            content: log
          }
        ]
      }
    )

    summary = response.dig("choices", 0, "message", "content")

    if summary.present?
      document.update!(summary: summary)
      format_daily_summary(document, summary)
    else
      log
    end
  rescue StandardError => e
    Rails.logger.warn(
      "Summarization failed: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    )

    log
  end

  def format_daily_summary(document, summary)
    <<~TEXT
      Source: #{document.title}
      Metadata: #{document.metadata.slice("date", "weekday", "category").to_json}

      #{summary}
    TEXT
  end

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
        model: LLM_MODEL,
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

              If multiple daily logs are provided:
              - Organize the answer by date in chronological order
              - Use a clear timeline format (one section per day)
              - Include:
                - Work
                - Activities
                - Projects
                - Meals
                - Notes (if available)

              Keep the answer structured and easy to scan. Avoid long paragraphs.

              Answer using only the provided context.

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
