class AddUniqueIndexForDailyLogDates < ActiveRecord::Migration[8.1]
  def up
    remove_duplicate_daily_logs

    add_index :documents,
      "(metadata->>'date')",
      unique: true,
      where: "doc_type = 'daily_log'",
      name: "index_documents_on_daily_log_date"
  end

  def down
    remove_index :documents, name: "index_documents_on_daily_log_date"
  end

  private

  def remove_duplicate_daily_logs
    duplicate_dates = execute(<<~SQL.squish)
      SELECT metadata->>'date' AS log_date
      FROM documents
      WHERE doc_type = 'daily_log'
        AND metadata->>'date' IS NOT NULL
      GROUP BY metadata->>'date'
      HAVING COUNT(*) > 1
    SQL

    duplicate_dates.each do |row|
      log_date = row["log_date"]

      ids_to_delete = execute(<<~SQL.squish)
        SELECT id
        FROM documents
        WHERE doc_type = 'daily_log'
          AND metadata->>'date' = #{connection.quote(log_date)}
        ORDER BY id DESC
        OFFSET 1
      SQL

      ids = ids_to_delete.map { |record| record["id"] }

      next if ids.empty?

      execute <<~SQL.squish
        DELETE FROM documents
        WHERE id IN (#{ids.join(",")})
      SQL
    end
  end
end
