# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_21_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "daily_stocks", force: :cascade do |t|
    t.date "date"
    t.integer "total"
    t.integer "used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_stocks_on_date", unique: true
  end

  create_table "delivery_assignments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_id", null: false
    t.datetime "assigned_at"
    t.datetime "departed_at"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "assigned", null: false
    t.index ["order_id"], name: "index_delivery_assignments_on_order_id"
    t.index ["user_id"], name: "index_delivery_assignments_on_user_id"
  end

  create_table "delivery_locations", force: :cascade do |t|
    t.bigint "delivery_assignment_id", null: false
    t.decimal "latitude"
    t.decimal "longitude"
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_assignment_id"], name: "index_delivery_locations_on_delivery_assignment_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "name"
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "available", default: true, null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_menu_items_on_category_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "menu_item_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_item_id"], name: "index_order_items_on_menu_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "modality", default: 0, null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "payment_method", default: 0, null: false
    t.string "delivery_address"
    t.bigint "created_by_id"
    t.bigint "cancelled_by_id"
    t.datetime "cancelled_at"
    t.string "cancellation_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending_payment", null: false
    t.float "latitude"
    t.float "longitude"
    t.decimal "delivery_fee", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["cancelled_by_id"], name: "index_orders_on_cancelled_by_id"
    t.index ["created_by_id"], name: "index_orders_on_created_by_id"
    t.index ["latitude", "longitude"], name: "index_orders_on_latitude_and_longitude"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.string "name"
    t.string "avatar_url"
    t.integer "role"
    t.integer "status"
    t.string "default_address"
    t.string "api_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "delivery_assignments", "orders"
  add_foreign_key "delivery_assignments", "users"
  add_foreign_key "delivery_locations", "delivery_assignments"
  add_foreign_key "menu_items", "categories"
  add_foreign_key "order_items", "menu_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "cancelled_by_id"
  add_foreign_key "orders", "users", column: "created_by_id"
end
