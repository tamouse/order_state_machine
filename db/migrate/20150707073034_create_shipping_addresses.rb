class CreateShippingAddresses < ActiveRecord::Migration
  def change
    create_table :shipping_addresses do |t|
      t.string :zip
      t.belongs_to :order, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
