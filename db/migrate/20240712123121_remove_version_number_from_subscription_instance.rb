class RemoveVersionNumberFromSubscriptionInstance < ActiveRecord::Migration[7.0]
  def change
    remove_column :subscription_instances, :version_number, :integer
  end
end
