class CreateProgresses < ActiveRecord::Migration[5.2]
  def change
      create_table :progresses do |t|
          t.string :recordID
          t.string :progress
          
          t.timestamps null: false
      end
  end
end
