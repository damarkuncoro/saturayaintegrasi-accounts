# frozen_string_literal: true

class CreateSolidQueue < ActiveRecord::Migration[8.1]
  def change
    # 22. Solid Queue Blocked Executions Table
    create_table "solid_queue_blocked_executions", force: :cascade do |t|
      t.string "concurrency_key", null: false
      t.datetime "expires_at", null: false
      t.bigint "job_id", null: false
      t.integer "priority", default: 0, null: false
      t.string "queue_name", null: false
      t.timestamps

      t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
      t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
      t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
    end

    # 23. Solid Queue Claimed Executions Table
    create_table "solid_queue_claimed_executions", force: :cascade do |t|
      t.bigint "job_id", null: false
      t.bigint "process_id"
      t.timestamps

      t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
      t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
    end

    # 24. Solid Queue Failed Executions Table
    create_table "solid_queue_failed_executions", force: :cascade do |t|
      t.text "error"
      t.bigint "job_id", null: false
      t.timestamps

      t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
    end

    # 25. Solid Queue Jobs Table
    create_table "solid_queue_jobs", force: :cascade do |t|
      t.string "active_job_id"
      t.text "arguments"
      t.string "class_name", null: false
      t.string "concurrency_key"
      t.datetime "finished_at"
      t.integer "priority", default: 0, null: false
      t.string "queue_name", null: false
      t.datetime "scheduled_at"
      t.timestamps

      t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
      t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
      t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
      t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
      t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
    end

    # 26. Solid Queue Pauses Table
    create_table "solid_queue_pauses", force: :cascade do |t|
      t.string "queue_name", null: false
      t.timestamps

      t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
    end

    # 27. Solid Queue Processes Table
    create_table "solid_queue_processes", force: :cascade do |t|
      t.string "hostname"
      t.string "kind", null: false
      t.datetime "last_heartbeat_at", null: false
      t.text "metadata"
      t.string "name", null: false
      t.integer "pid", null: false
      t.bigint "supervisor_id"
      t.timestamps

      t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
      t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
      t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
    end

    # 28. Solid Queue Ready Executions Table
    create_table "solid_queue_ready_executions", force: :cascade do |t|
      t.bigint "job_id", null: false
      t.integer "priority", default: 0, null: false
      t.string "queue_name", null: false
      t.timestamps

      t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
      t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
      t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
    end

    # 29. Solid Queue Recurring Executions Table
    create_table "solid_queue_recurring_executions", force: :cascade do |t|
      t.bigint "job_id", null: false
      t.datetime "run_at", null: false
      t.string "task_key", null: false
      t.timestamps

      t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
      t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
    end

    # 30. Solid Queue Recurring Tasks Table
    create_table "solid_queue_recurring_tasks", force: :cascade do |t|
      t.text "arguments"
      t.string "class_name"
      t.string "command", limit: 2048
      t.text "description"
      t.string "key", null: false
      t.integer "priority", default: 0
      t.string "queue_name"
      t.string "schedule", null: false
      t.boolean "static", default: true, null: false
      t.timestamps

      t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
      t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
    end

    # 31. Solid Queue Scheduled Executions Table
    create_table "solid_queue_scheduled_executions", force: :cascade do |t|
      t.bigint "job_id", null: false
      t.integer "priority", default: 0, null: false
      t.string "queue_name", null: false
      t.datetime "scheduled_at", null: false
      t.timestamps

      t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
      t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
    end

    # 32. Solid Queue Semaphores Table
    create_table "solid_queue_semaphores", force: :cascade do |t|
      t.datetime "expires_at", null: false
      t.string "key", null: false
      t.integer "value", default: 1, null: false
      t.timestamps

      t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
      t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
      t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
    end

    # Foreign Keys for Solid Queue
    add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
    add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
    add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
    add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
    add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
    add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  end
end
