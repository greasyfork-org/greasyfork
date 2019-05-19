class AddObjectTypeToDisallowedAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :disallowed_attributes, :object_type, :string
    DisallowedAttribute.update_all(object_type: 'script')
    change_column_null :disallowed_attributes, :object_type, false
  end
end
