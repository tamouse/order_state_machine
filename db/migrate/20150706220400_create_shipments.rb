class CreateShipments < ActiveRecord::Migration
  def change
    create_table :shipments do |t|
      t.datetime :shipped_at
      t.boolean :shipped
      t.belongs_to :order, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
