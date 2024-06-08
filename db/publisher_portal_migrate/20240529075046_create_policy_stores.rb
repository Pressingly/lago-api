class CreatePolicyStores < ActiveRecord::Migration[7.0]
  def change
    create_table :policy_stores, id: :uuid do |t|
      t.string :policy_store_id
      t.string :namespace
      t.json :schema

      t.timestamps
    end
  end
end
