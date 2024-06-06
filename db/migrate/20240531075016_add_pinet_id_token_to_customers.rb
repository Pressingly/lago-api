class AddPinetIdTokenToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :pinet_id_token, :string
  end
end
