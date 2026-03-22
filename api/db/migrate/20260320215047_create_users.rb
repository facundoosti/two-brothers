class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :email
      t.string :name
      t.string :avatar_url
      t.integer :role
      t.integer :status
      t.string :default_address
      t.string :api_token

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :api_token, unique: true
  end
end
