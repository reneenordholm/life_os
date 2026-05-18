class CreateCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_events do |t|
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :location
      t.string :source
      t.string :external_id

      t.timestamps
    end
  end
end
