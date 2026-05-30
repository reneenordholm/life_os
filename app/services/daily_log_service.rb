class DailyLogService
  def self.create_or_update_for_date(date, content)
    retries = 0

    begin
      title = "📓 Daily Log — #{date}"

      doc = Document
        .where(doc_type: "daily_log")
        .where("metadata ->> 'date' = ?", date.to_s)
        .first_or_initialize

      doc.assign_attributes(
        title: title,
        doc_type: "daily_log",
        content: content,
        metadata: {
          "date" => date.to_s,
          "weekday" => date.strftime("%A"),
          "category" => "daily"
        }
      )

      doc.save!
      doc
    rescue ActiveRecord::RecordNotUnique
      retries += 1
      retry if retries <= 1

      raise
    end
  end

  def self.create_today(content)
    create_or_update_for_date(Date.current, content)
  end
end
