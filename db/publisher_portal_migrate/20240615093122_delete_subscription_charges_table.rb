class DeleteSubscriptionChargesTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :subscription_charges # rubocop:disable Rails/ReversibleMigration
  end
end
