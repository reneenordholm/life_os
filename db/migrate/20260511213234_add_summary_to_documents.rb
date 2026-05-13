class AddSummaryToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :summary, :text
  end
end
