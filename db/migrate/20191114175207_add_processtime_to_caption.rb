class AddProcesstimeToCaption < ActiveRecord::Migration[5.2]
  def change
    add_column :captions, :processtime, :string
  end
end
