class BackfillDocumentMetadata < ActiveRecord::Migration[8.1]
  def up
    Document.find_each do |doc|
      metadata = doc.metadata || {}

      #
      # 📓 Daily Logs
      #
      if doc.doc_type == "daily_log"
        date_match = doc.title.match(/(\d{4}-\d{2}-\d{2})/)

        if date_match
          date = Date.parse(date_match[1])

          metadata["date"] ||= date.to_s
          metadata["weekday"] ||= date.strftime("%A")
          metadata["category"] ||= "daily"
        end
      end

      #
      # 🐱 Marley Veterinary Records
      #
      if doc.title.include?("Marley")
        metadata["person"] ||= "Marley"
        metadata["species"] ||= "cat"
        metadata["category"] ||= "veterinary"
      end

      #
      # ✈️ Itinerary / Travel
      #
      if doc.doc_type == "itinerary"
        metadata["category"] ||= "travel"

        if doc.title.downcase.include?("mom")
          metadata["person"] ||= "Mom"
        end
      end

      #
      # 🍳 Recipes
      #
      if doc.doc_type == "recipe"
        metadata["category"] ||= "recipe"
      end

      #
      # 🛒 Grocery
      #
      if doc.doc_type == "grocery"
        metadata["category"] ||= "grocery"
      end

      doc.update_columns(metadata: metadata)
    end
  end

  def down
    Document.update_all(metadata: {})
  end
end
