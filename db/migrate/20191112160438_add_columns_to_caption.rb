class AddColumnsToCaption < ActiveRecord::Migration[5.2]
  def change
    add_column :captions, :bbb_url, :string
    add_column :captions, :bbb_checksum, :string
    add_column :captions, :kind, :string
    add_column :captions, :label, :string
    add_column :captions, :processing_time, :integer
  end
end
