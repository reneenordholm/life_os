class CreateDocumentEntities < ActiveRecord::Migration[8.1]
  def change
    create_table :document_entities do |t|
      t.references :document, null: false, foreign_key: true
      t.references :entity, null: false, foreign_key: true

      t.timestamps
    end
  end
end
