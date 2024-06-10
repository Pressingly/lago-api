class CreateSubscriptionInstanceItems < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_instance_items, id: :uuid do |t|
      t.references :subscription_instance, null: false, foreign_key: true, type: :uuid
      t.bigint :fee_amount_cents, default: 0, null: false
      t.string :charge_type, null: false
      t.string :code

      t.timestamps
    end
  end
end
