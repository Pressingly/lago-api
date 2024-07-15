class AddContractStatusToSubscriptionInstanceItem < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_instance_items, :contract_status, :string, null: false, default: 'pending'
  end
end
