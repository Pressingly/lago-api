class CreateSubscriptionInstances < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_instances, id: :uuid do |t|
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.datetime :started_at
      t.datetime :ended_at
      t.uuid :pinet_transaction_charge_id
      t.decimal :total_amount, precision: 30, scale: 15, default: "0.0", null: false
      t.string :status, null: false
      t.integer :version_number, default: 0, null: false

      t.timestamps
    end
  end
end
