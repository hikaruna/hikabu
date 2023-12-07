class CreateTables < ActiveRecord::Migration[7.1]
  def change
    create_table :stocks, id: false, primary_key: :code do |t|
      t.integer :code, null: false, index: { unique: true }
      t.string :name
      t.integer :price

      t.timestamps
    end

    create_table :owned_stocks, id: false, primary_key: [ :code, :account_type ] do |t|
      t.integer :code, null: false, index: { unique: true }
      t.integer :holdings
      t.integer :average_acquisition_price
      t.string :account_type

      t.timestamps
    end
    add_foreign_key :owned_stocks, :stocks, column: :code, primary_key: :code
  end
end
