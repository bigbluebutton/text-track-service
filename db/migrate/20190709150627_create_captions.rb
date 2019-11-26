# rubocop:disable Style/Documentation
# frozen_string_literal: true

class CreateCaptions < ActiveRecord::Migration[5.2]
  def change
    create_table :captions do |t|
      t.string :record_id
      t.string :service
      t.string :status
      t.string :caption_locale
      t.string :error
      t.string :bbb_url
      t.string :bbb_checksum
      t.string :kind
      t.string :label
      t.string :processtime
      t.string :start_time
      t.string :end_time

      t.timestamps
    end
  end
end
# rubocop:enable Style/Documentation
