class CreateDeliverySettings < ActiveRecord::Migration[7.2]
  def change
    create_table :delivery_settings do |t|
      t.integer :user_id
      t.time :delivery_time
      t.string :frequency

      t.timestamps
    end
  end
end
