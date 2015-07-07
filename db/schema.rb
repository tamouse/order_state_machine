# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150707073034) do

  create_table "orders", force: :cascade do |t|
    t.string   "po_number"
    t.string   "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_methods", force: :cascade do |t|
    t.boolean  "declined",   default: false, null: false
    t.integer  "order_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "payment_methods", ["order_id"], name: "index_payment_methods_on_order_id"

  create_table "shipments", force: :cascade do |t|
    t.datetime "shipped_at"
    t.boolean  "shipped"
    t.integer  "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "shipments", ["order_id"], name: "index_shipments_on_order_id"

  create_table "shipping_addresses", force: :cascade do |t|
    t.string   "zip"
    t.integer  "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "shipping_addresses", ["order_id"], name: "index_shipping_addresses_on_order_id"

end
