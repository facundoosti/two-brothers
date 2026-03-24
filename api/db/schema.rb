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

ActiveRecord::Schema[8.0].define(version: 2026_03_23_213554) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "billing_periods", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "billing_month_number", null: false
    t.string "plan", null: false
    t.decimal "usd_base", precision: 10, scale: 2, null: false
    t.decimal "blue_rate", precision: 10, scale: 2, null: false
    t.decimal "base_ars", precision: 14, scale: 2, null: false
    t.decimal "variable_pct", precision: 5, scale: 4, null: false
    t.decimal "delivered_sales_ars", precision: 14, scale: 2, null: false
    t.decimal "variable_ars", precision: 14, scale: 2, null: false
    t.decimal "total_ars", precision: 14, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.date "due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_billing_periods_on_due_date"
    t.index ["status"], name: "index_billing_periods_on_status"
    t.index ["subscription_id", "year", "month"], name: "index_billing_periods_on_subscription_id_and_year_and_month", unique: true
    t.index ["subscription_id"], name: "index_billing_periods_on_subscription_id"
  end

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
    t.bigint "menu_item_id", null: false
    t.index ["menu_item_id", "date"], name: "index_daily_stocks_on_menu_item_id_and_date", unique: true
    t.index ["menu_item_id"], name: "index_daily_stocks_on_menu_item_id"
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

  create_table "exchange_rates", force: :cascade do |t|
    t.integer "year", null: false
    t.integer "month", null: false
    t.decimal "blue_rate", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "month"], name: "index_exchange_rates_on_year_and_month", unique: true
  end

  create_table "menu_items", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "name"
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "available", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_stock"
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
    t.boolean "paid", default: false, null: false
    t.datetime "confirmed_at"
    t.datetime "preparing_at"
    t.datetime "ready_at"
    t.datetime "delivering_at"
    t.datetime "delivered_at"
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

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.date "started_at", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "status"], name: "index_subscriptions_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_subscriptions_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "billing_periods", "subscriptions"
  add_foreign_key "daily_stocks", "menu_items"
  add_foreign_key "delivery_assignments", "orders"
  add_foreign_key "delivery_assignments", "users"
  add_foreign_key "delivery_locations", "delivery_assignments"
  add_foreign_key "menu_items", "categories"
  add_foreign_key "order_items", "menu_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "cancelled_by_id"
  add_foreign_key "orders", "users", column: "created_by_id"
  add_foreign_key "subscriptions", "tenants"
end
