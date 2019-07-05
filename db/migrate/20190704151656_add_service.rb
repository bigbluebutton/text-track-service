class AddService < ActiveRecord::Migration[5.2]
  def change
      change_table :progresses do |t|
          t.string :service
          
      end
      
  end
end
