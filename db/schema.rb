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

ActiveRecord::Schema[8.1].define(version: 2026_09_21_090000) do
  create_table "activity_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "ip_address"
    t.integer "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_activity_logs_on_target_type_and_target_id"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "auditoria", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "total_seats"
    t.datetime "updated_at", null: false
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "qr_code_token"
    t.integer "seat_id", null: false
    t.integer "showtime_id", null: false
    t.decimal "total_price"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["qr_code_token"], name: "index_bookings_on_qr_code_token", unique: true
    t.index ["seat_id"], name: "index_bookings_on_seat_id"
    t.index ["showtime_id", "seat_id"], name: "index_bookings_on_showtime_and_seat", unique: true
    t.index ["showtime_id"], name: "index_bookings_on_showtime_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "movies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes"
    t.integer "lock_version", default: 0, null: false
    t.string "poster_url"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "seat_holds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "seat_id", null: false
    t.integer "showtime_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["expires_at"], name: "index_seat_holds_on_expires_at"
    t.index ["seat_id"], name: "index_seat_holds_on_seat_id"
    t.index ["showtime_id", "seat_id"], name: "index_seat_holds_on_showtime_and_seat", unique: true
    t.index ["showtime_id"], name: "index_seat_holds_on_showtime_id"
    t.index ["user_id"], name: "index_seat_holds_on_user_id"
  end

  create_table "seats", force: :cascade do |t|
    t.integer "auditorium_id", null: false
    t.datetime "created_at", null: false
    t.integer "number"
    t.string "row"
    t.datetime "updated_at", null: false
    t.index ["auditorium_id"], name: "index_seats_on_auditorium_id"
  end

  create_table "showtimes", force: :cascade do |t|
    t.integer "auditorium_id", null: false
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "movie_id", null: false
    t.decimal "price"
    t.datetime "start_time"
    t.datetime "updated_at", null: false
    t.index ["auditorium_id"], name: "index_showtimes_on_auditorium_id"
    t.index ["movie_id"], name: "index_showtimes_on_movie_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "bookings", "seats"
  add_foreign_key "bookings", "showtimes"
  add_foreign_key "bookings", "users"
  add_foreign_key "seat_holds", "seats"
  add_foreign_key "seat_holds", "showtimes"
  add_foreign_key "seat_holds", "users"
  add_foreign_key "seats", "auditoria"
  add_foreign_key "showtimes", "auditoria"
  add_foreign_key "showtimes", "movies"
end
