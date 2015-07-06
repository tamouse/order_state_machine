class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :po_number
      t.string :aasm_state

      t.timestamps null: false
    end
  end
end
