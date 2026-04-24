class CreateEntities < ActiveRecord::Migration[8.1]
  def change
    create_table :entities do |t|
      t.string :name
      t.string :entity_type
      t.jsonb :metadata

      t.timestamps
    end
  end
end
