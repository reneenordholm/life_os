class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :doc_type
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :documents, :doc_type
  end
end
