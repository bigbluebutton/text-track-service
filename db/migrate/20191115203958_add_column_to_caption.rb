class AddColumnToCaption < ActiveRecord::Migration[5.2]
  def change
    add_column :captions, :start_time, :string
    add_column :captions, :duration, :string
  end
end
