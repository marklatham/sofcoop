class SetUserModDefault < ActiveRecord::Migration[5.1]
  def change
    change_column_null :users, :mod, false
    change_column_default :users, :mod, ""
  end
end
