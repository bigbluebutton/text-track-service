class CreateCaptions < ActiveRecord::Migration[5.2]
  def change
    create_table :captions do |t|
      t.string :recordID
      t.string :service
      t.string :progress

      t.timestamps
    end
  end
end
