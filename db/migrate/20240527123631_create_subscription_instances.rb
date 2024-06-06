class CreateSubscriptionInstances < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_instances, id: :uuid do |t|
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.datetime :started_at
      t.datetime :ended_at
      t.uuid :pinet_transaction_charge_id
      t.decimal :total_subscription_value, precision: 30, scale: 5, default: "0.0", null: false
      t.boolean :is_finalized, default: false

      t.timestamps
    end
  end
end
