class DailyLogSummaryService
  def self.call(document)
    new(document).call
  end

  def initialize(document)
    @document = document
  end

  def call
    return unless @document.doc_type == "daily_log"
    return if @document.content.blank?
    return if @document.summary.present?

    summary = generate_summary
    @document.update!(summary: summary) if summary.present?
  rescue StandardError => e
    Rails.logger.warn(
      "Daily log summary failed for Document##{@document.id}: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    )
  end

  private

  def generate_summary
    log = <<~LOG
      Source: #{@document.title}
      Metadata: #{(@document.metadata || {}).slice("date", "weekday", "category").to_json}

      #{@document.content}
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

    response.dig("choices", 0, "message", "content").presence
  end
end
