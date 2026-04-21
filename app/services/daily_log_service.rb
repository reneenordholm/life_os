class DailyLogService
  def self.create_today(content)
    today = Date.today
    doc = Document.create!(
      title: "📓 Daily Log — #{today.strftime('%A, %Y-%m-%d')}",
      doc_type: "daily_log",
      metadata: {
        date: today,
        weekday: today.strftime("%A")
      },
      content: content
    )

    DocumentIngestionService.new(doc).call

    doc
  end
end