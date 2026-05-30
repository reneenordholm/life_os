class DailyLogService
  def self.create_or_update_for_date(date, content)
    title = "📓 Daily Log — #{date}"

    doc = Document.find_or_initialize_by(
      doc_type: "daily_log",
      title: title
    )

    doc.assign_attributes(
      content: content,
      metadata: {
        "date" => date.to_s,
        "weekday" => date.strftime("%A"),
        "category" => "daily"
      }
    )

    doc.save!

    doc
  end

  def self.create_today(content)
    create_or_update_for_date(Date.current, content)
  end
end
