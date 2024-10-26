class LocaleIdBigint < ActiveRecord::Migration[7.2]
  def change
    [:locale_contributors, :localized_script_attributes, :localized_script_version_attributes, :scripts, :users].each do |table_name|
      next if bigint?(table_name, :locale_id)

      change_column table_name, :locale_id, :bigint
      add_foreign_key table_name, :locales
    end
  end

  def bigint?(table, col)
    Script.connection.columns(table.to_sym).find{|c| c.name == col.to_s}.sql_type == 'bigint(20)'
  end
end
