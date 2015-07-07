class CreatePaymentMethods < ActiveRecord::Migration
  def change
    create_table :payment_methods do |t|
      t.boolean    :declined, default: false, null: false
      t.belongs_to :order, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
