class UpdateDeliverySettings < ActiveRecord::Migration[7.2]
  def up
    change_table :delivery_settings do |t|
      t.remove :delivery_time
      t.time :delivery_time_1, null: false, default: "09:00"
      t.time :delivery_time_2
    end

    add_index :delivery_settings, :user_id, unique: true
  end

  def down
    remove_index :delivery_settings, :user_id
    change_table :delivery_settings do |t|
      t.remove :delivery_time_1
      t.remove :delivery_time_2
      t.time :delivery_time
    end
  end
end
