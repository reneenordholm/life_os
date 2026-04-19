class CreateDocumentChunks < ActiveRecord::Migration[7.0]
  def change
    create_table :document_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content, null: false
      t.vector :embedding, limit: 1536
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :document_chunks,
              :embedding,
              using: :ivfflat,
              opclass: :vector_cosine_ops
  end
end
