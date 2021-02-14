class AddExplanationMarkupToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :explanation_markup, :string, limit: 10
    execute 'update reports set explanation_markup = "text"'
    change_column_default :reports, :explanation_markup, 'html'
    change_column_null :reports, :explanation_markup, false
  end
end
