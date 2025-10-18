class CreateOutboxMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :outbox_messages do |t|
      t.string :aggregate_id, null: false
      t.string :aggregate_type, null: false
      t.string :event_type, null: false
      t.text :payload, null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.timestamp :published_at
      t.text :error_message

      t.timestamps
    end

    add_index :outbox_messages, [ :status, :created_at ]
    add_index :outbox_messages, [ :aggregate_type, :aggregate_id ]
  end
end
