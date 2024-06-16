class CreateSubscriptionInstanceItems < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_instance_items, id: :uuid do |t|
      t.references :subscription_instance, null: false, foreign_key: true, type: :uuid
      t.decimal :fee_amount, precision: 30, scale: 15, default: "0.0", null: false
      t.string :charge_type, null: false
      t.string :code

      t.timestamps
    end
  end
end
