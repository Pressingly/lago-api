class CreateAuthorizationPolicies < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_policies, id: :uuid do |t|
      t.string :cedar_policy_id
      t.string :plan_id

      t.timestamps
    end
  end
end
