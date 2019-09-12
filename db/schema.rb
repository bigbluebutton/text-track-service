# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_190_709_150_627) do
  create_table 'captions', force: :cascade do |t|
    t.string 'record_id'
    t.string 'service'
    t.string 'status'
    t.string 'caption_locale'
    t.string 'error'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end
end
