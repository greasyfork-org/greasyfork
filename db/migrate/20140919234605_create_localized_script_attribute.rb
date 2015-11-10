class CreateLocalizedScriptAttribute < ActiveRecord::Migration
	def change
		create_table :localized_script_attributes do |t|
			t.belongs_to :script, :index => true, :null => false
			t.belongs_to :locale, :index => true, :null => false
			t.string :attribute_key, :length => 20, :index => true, :null => false
			t.string :value_markup, :length => 10, :null => false
			t.text :attribute_value, :length => 50000, :null => false
			t.boolean :attribute_default, :null => false
		end
		create_table :localized_script_version_attributes do |t|
			t.belongs_to :script_version, :index => true, :null => false
			t.belongs_to :locale, :index => true, :null => false
			t.string :attribute_key, :length => 20, :index => true, :null => false
			t.string :value_markup, :length => 10, :null => false
			t.text :attribute_value, :length => 50000, :null => false
			t.boolean :attribute_default, :null => false
		end
		change_table(:scripts) do |t|
			t.string :default_name, :length => 100, :null => false
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					update scripts set default_name = name
				EOF
				execute <<-EOF
					update scripts join locales set locale_id = locales.id where locale_id is null and code = 'en'
				EOF
				execute <<-EOF
					insert into localized_script_attributes (script_id, locale_id, attribute_key, value_markup, attribute_value, attribute_default) select id, locale_id, 'name', 'text', name, true from scripts
				EOF
				execute <<-EOF
					insert into localized_script_attributes (script_id, locale_id, attribute_key, value_markup, attribute_value, attribute_default) select id, locale_id, 'description', 'text', description, true from scripts
				EOF
				execute <<-EOF
					insert into localized_script_attributes (script_id, locale_id, attribute_key, value_markup, attribute_value, attribute_default) select id, locale_id, 'additional_info', additional_info_markup, additional_info, true from scripts where additional_info is not null
				EOF
				execute <<-EOF
					insert into localized_script_version_attributes (script_version_id, locale_id, attribute_key, value_markup, attribute_value, attribute_default) select script_versions.id, locale_id, 'additional_info', script_versions.additional_info_markup, script_versions.additional_info, true from script_versions join scripts on script_id = scripts.id where script_versions.additional_info is not null
				EOF
			end
		end
		change_table(:scripts) do |t|
			t.remove :name
			t.remove :description
			t.remove :additional_info
			t.remove :additional_info_markup
		end
		change_table(:script_versions) do |t|
			t.remove :additional_info
			t.remove :additional_info_markup
		end
	end
end
