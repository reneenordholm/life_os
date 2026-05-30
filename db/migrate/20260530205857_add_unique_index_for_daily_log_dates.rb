class AddUniqueIndexForDailyLogDates < ActiveRecord::Migration[8.1]
  def change
    add_index :documents,
      "(metadata->>'date')",
      unique: true,
      where: "doc_type = 'daily_log'",
      name: "index_documents_on_daily_log_date"
  end
end
