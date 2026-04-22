class DailyLogService
  def self.create_for_date(date, content)
    title = "📓 Daily Log — #{date}"

    doc = Document.create!(
      title: title,
      doc_type: "daily_log",
      content: content,
      metadata: {
        "date" => date.to_s,
        "weekday" => date.strftime("%A"),
        "category" => "daily"
      }
    )

    DocumentIngestionService.new(doc).call

    doc
  end

  def self.create_today(content)
    create_for_date(Date.today, content)
  end
end