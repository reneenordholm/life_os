class DailyLogService
  def self.create_today(content)
    doc = Document.create!(
      title: "📓 Daily Log — #{Date.today}",
      doc_type: "daily_log",
      content: content
    )

    DocumentIngestionService.new(doc).call

    doc
  end
end
