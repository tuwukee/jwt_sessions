class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :email, default: '', null: false
      t.string :password_digest

      t.timestamps
    end
  end
end
