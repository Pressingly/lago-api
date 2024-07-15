class AddOrganizationIdToPolicyStores < ActiveRecord::Migration[7.0]
  def change
    add_column :policy_stores, :organization_id, :string
  end
end
