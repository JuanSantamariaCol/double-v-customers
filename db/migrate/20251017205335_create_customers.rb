class CreateCustomers < ActiveRecord::Migration[7.2]
  def change
    create_table :customers do |t|
      t.string :name, null: false, limit: 255
      t.integer :person_type, null: false, limit: 2, default: 0
      t.string :identification, null: false, limit: 50
      t.string :email, null: false, limit: 255
      t.string :phone, limit: 20
      t.string :address, null: false, limit: 500
      t.integer :active, null: false, default: 1

      t.timestamps
    end

    add_index :customers, :identification, unique: true
    add_index :customers, :email
    add_index :customers, :active
  end
end
