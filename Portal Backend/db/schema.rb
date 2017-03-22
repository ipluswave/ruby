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

ActiveRecord::Schema.define(version: 20170224062027) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.string   "label"
    t.string   "organization_name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.string   "country"
    t.integer  "organization_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "primary",           default: false
    t.integer  "contact_id"
  end

  add_index "addresses", ["address1"], name: "index_addresses_on_address1", using: :btree
  add_index "addresses", ["label"], name: "index_addresses_on_label", using: :btree
  add_index "addresses", ["organization_name"], name: "index_addresses_on_organization_name", using: :btree

  create_table "bootsy_image_galleries", force: :cascade do |t|
    t.integer  "bootsy_resource_id"
    t.string   "bootsy_resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bootsy_images", force: :cascade do |t|
    t.string   "image_file"
    t.integer  "image_gallery_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "card_images", force: :cascade do |t|
    t.string   "file"
    t.string   "token"
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "card_images", ["imageable_type", "imageable_id"], name: "index_card_images_on_imageable_type_and_imageable_id", using: :btree

  create_table "card_options", force: :cascade do |t|
    t.string   "element"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "card_print_histories", force: :cascade do |t|
    t.integer  "cards_id"
    t.integer  "user_data_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "card_print_histories", ["cards_id"], name: "index_card_print_histories_on_cards_id", using: :btree
  add_index "card_print_histories", ["user_data_id"], name: "index_card_print_histories_on_user_data_id", using: :btree

  create_table "card_templates", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "organization_id"
    t.integer  "card_type_id"
    t.text     "front_data",              default: ""
    t.json     "options",                 default: []
    t.json     "template_fields",         default: []
    t.text     "back_data",               default: ""
    t.json     "card_data",               default: []
    t.integer  "status_cd",               default: 0
    t.integer  "master_card_template_id"
  end

  add_index "card_templates", ["card_type_id"], name: "index_card_templates_on_card_type_id", using: :btree
  add_index "card_templates", ["name"], name: "index_card_templates_on_name", using: :btree
  add_index "card_templates", ["organization_id"], name: "index_card_templates_on_organization_id", using: :btree

  create_table "card_templates_special_handlings", id: false, force: :cascade do |t|
    t.integer "card_template_id"
    t.integer "special_handling_id"
  end

  add_index "card_templates_special_handlings", ["card_template_id"], name: "index_card_templates_special_handlings_on_card_template_id", using: :btree
  add_index "card_templates_special_handlings", ["special_handling_id"], name: "index_card_templates_special_handlings_on_special_handling_id", using: :btree

  create_table "card_types", force: :cascade do |t|
    t.integer  "type"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.float    "width",       default: 457.0
    t.float    "height",      default: 288.0
  end

  create_table "card_types_printers", id: false, force: :cascade do |t|
    t.integer "card_type_id"
    t.integer "printer_id"
  end

  add_index "card_types_printers", ["card_type_id"], name: "index_card_types_printers_on_card_type_id", using: :btree
  add_index "card_types_printers", ["printer_id"], name: "index_card_types_printers_on_printer_id", using: :btree

  create_table "cards", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "card_template_id"
    t.json     "data",             default: []
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "cards", ["card_template_id"], name: "index_cards_on_card_template_id", using: :btree
  add_index "cards", ["organization_id"], name: "index_cards_on_organization_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "full_name"
    t.string   "email"
    t.string   "alt_email"
    t.string   "phone_number"
    t.string   "alt_phone_number"
    t.integer  "organization_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "fax_number"
  end

  add_index "contacts", ["email"], name: "index_contacts_on_email", using: :btree
  add_index "contacts", ["full_name"], name: "index_contacts_on_full_name", using: :btree
  add_index "contacts", ["organization_id"], name: "index_contacts_on_organization_id", using: :btree

  create_table "costs", force: :cascade do |t|
    t.money    "value",           scale: 2
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "costable_id"
    t.string   "costable_type"
    t.integer  "organization_id"
    t.integer  "range_low",                 default: 0
    t.integer  "range_high",                default: 0
  end

  add_index "costs", ["organization_id"], name: "index_costs_on_organization_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "financial_transaction_sub_types", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "financial_transaction_type_id", default: 0
  end

  add_index "financial_transaction_sub_types", ["name"], name: "index_financial_transaction_sub_types_on_name", using: :btree

  create_table "financial_transaction_types", force: :cascade do |t|
    t.integer "transaction_type"
    t.string  "name"
  end

  add_index "financial_transaction_types", ["transaction_type"], name: "index_financial_transaction_types_on_transaction_type", using: :btree

  create_table "financial_transactions", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.text     "description"
    t.integer  "operation_cd"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.money    "credit",                            scale: 2, default: 0.0
    t.money    "balance",                           scale: 2
    t.integer  "financial_transaction_sub_type_id"
    t.money    "debit",                             scale: 2, default: 0.0
    t.integer  "print_job_id"
  end

  add_index "financial_transactions", ["financial_transaction_sub_type_id"], name: "financial_transaction_sub_type_id", using: :btree

  create_table "font_files", force: :cascade do |t|
    t.integer  "fontfileable_id"
    t.string   "fontfileable_type"
    t.string   "stretch"
    t.string   "style"
    t.string   "weight"
    t.string   "file"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "font_files", ["fontfileable_type", "fontfileable_id"], name: "index_font_files_on_fontfileable_type_and_fontfileable_id", using: :btree

  create_table "fonts", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.json     "files",      default: []
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "global"
  end

  create_table "fonts_organizations", id: false, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "font_id"
  end

  add_index "fonts_organizations", ["font_id"], name: "index_fonts_organizations_on_font_id", using: :btree
  add_index "fonts_organizations", ["organization_id"], name: "index_fonts_organizations_on_organization_id", using: :btree

  create_table "images", force: :cascade do |t|
    t.string   "file"
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "images", ["imageable_type", "imageable_id"], name: "index_images_on_imageable_type_and_imageable_id", using: :btree

  create_table "industries", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "label_templates", force: :cascade do |t|
    t.text     "template"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type_cd",         default: 0
    t.text     "to_address",      default: ""
  end

  create_table "legacy_card_types", force: :cascade do |t|
    t.integer  "legacy_card_type_id"
    t.string   "name"
    t.boolean  "mag_stripe"
    t.boolean  "double_sided"
    t.string   "cart_type_name"
    t.integer  "card_type_id"
    t.boolean  "slot_punch"
    t.boolean  "overlay"
    t.boolean  "color_color"
    t.boolean  "drop_ship"
    t.string   "accessories"
    t.boolean  "grommet"
    t.boolean  "hole_punch"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "double_overlay",      default: false
  end

  create_table "letter_templates", force: :cascade do |t|
    t.text     "template"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",            default: ""
    t.string   "paper_type",      default: "default"
    t.integer  "margin_top",      default: 10
    t.integer  "margin_bottom",   default: 10
    t.integer  "margin_left",     default: 10
    t.integer  "margin_right",    default: 10
    t.string   "page_size",       default: "Letter"
    t.string   "orientation",     default: "Portrait"
    t.integer  "font_id"
    t.integer  "font_size",       default: 10
    t.integer  "line_height",     default: 15
  end

  create_table "list_users", force: :cascade do |t|
    t.integer  "print_job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "list_users", ["print_job_id"], name: "index_list_users_on_print_job_id", using: :btree

  create_table "migration_logs", force: :cascade do |t|
    t.integer  "migration_task_id"
    t.integer  "organization_id"
    t.text     "message"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "status_cd",         default: 0
  end

  add_index "migration_logs", ["migration_task_id"], name: "index_migration_logs_on_migration_task_id", using: :btree
  add_index "migration_logs", ["organization_id"], name: "index_migration_logs_on_organization_id", using: :btree

  create_table "migration_tasks", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "from_organization_id"
    t.integer  "to_organization_id"
    t.integer  "status_cd",            default: 0
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "migration_tasks_organizations", id: false, force: :cascade do |t|
    t.integer "migration_task_id"
    t.integer "organization_id"
  end

  add_index "migration_tasks_organizations", ["migration_task_id"], name: "index_migration_tasks_organizations_on_migration_task_id", using: :btree
  add_index "migration_tasks_organizations", ["organization_id"], name: "index_migration_tasks_organizations_on_organization_id", using: :btree

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.string   "legacy_id"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.money    "balance",                      scale: 2, default: 0.0
    t.money    "overdraft",                    scale: 2, default: 25.0
    t.integer  "parent_organization_id"
    t.integer  "industry_id"
    t.integer  "category_id"
    t.integer  "system_cd",                              default: 1
    t.money    "legacy_balance",               scale: 2
    t.integer  "status_cd",                              default: 0
    t.integer  "migration_status_cd"
    t.datetime "last_financial_transaction"
    t.integer  "total_jobs",                             default: 0
    t.integer  "approved_card_template_count",           default: 0
    t.json     "settings",                               default: {}
  end

  add_index "organizations", ["name"], name: "index_organizations_on_name", using: :btree
  add_index "organizations", ["status_cd"], name: "index_organizations_on_status_cd", using: :btree

  create_table "organizations_card_types", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "card_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "print_jobs", force: :cascade do |t|
    t.integer  "card_template_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "status_cd",            default: 0
    t.text     "status_message",       default: ""
    t.text     "address",              default: ""
    t.integer  "shipping_provider_id", default: 1
    t.integer  "workstation_id"
    t.integer  "type_cd",              default: 0
    t.boolean  "charge",               default: true
    t.json     "context",              default: {}
    t.integer  "number_of_copies",     default: 1
    t.boolean  "is_sample",            default: false
    t.integer  "total_cards",          default: 0
    t.string   "special_handlings"
    t.integer  "organization_id"
    t.datetime "printed_at"
    t.integer  "address_id"
    t.integer  "api_version_cd",       default: 0
  end

  add_index "print_jobs", ["address_id"], name: "index_print_jobs_on_address_id", using: :btree
  add_index "print_jobs", ["card_template_id"], name: "index_print_jobs_on_card_template_id", using: :btree
  add_index "print_jobs", ["printed_at"], name: "index_print_jobs_on_printed_at", using: :btree

  create_table "printers", force: :cascade do |t|
    t.string   "name"
    t.integer  "workstation_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "print_label",    default: false
    t.boolean  "print_letter",   default: false
  end

  add_index "printers", ["workstation_id"], name: "index_printers_on_workstation_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "shared_templates", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "card_template_id"
    t.integer "clone_card_template_id"
  end

  add_index "shared_templates", ["card_template_id"], name: "index_shared_templates_on_card_template_id", using: :btree
  add_index "shared_templates", ["organization_id"], name: "index_shared_templates_on_organization_id", using: :btree

  create_table "shipping_providers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sites", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "special_handlings", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token",           default: ""
    t.integer  "organization_id"
  end

  create_table "transaction_items", force: :cascade do |t|
    t.integer  "total"
    t.money    "value",                    scale: 2
    t.integer  "financial_transaction_id"
    t.integer  "cost_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_data", force: :cascade do |t|
    t.integer  "list_user_id"
    t.integer  "users_id"
    t.json     "data",             default: []
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_cd",        default: 0
    t.integer  "card_template_id"
    t.integer  "card_id"
  end

  add_index "user_data", ["card_id"], name: "index_user_data_on_card_id", using: :btree
  add_index "user_data", ["card_template_id"], name: "index_user_data_on_card_template_id", using: :btree
  add_index "user_data", ["list_user_id"], name: "index_user_data_on_list_user_id", using: :btree
  add_index "user_data", ["users_id"], name: "index_user_data_on_users_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.string   "pin"
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.json     "settings",               default: {}
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["pin"], name: "index_users_on_pin", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "workstations", force: :cascade do |t|
    t.string   "name"
    t.integer  "site_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "workers_queue", default: "print"
    t.integer  "status_cd",     default: 1
  end

  add_index "workstations", ["site_id"], name: "index_workstations_on_site_id", using: :btree

end
