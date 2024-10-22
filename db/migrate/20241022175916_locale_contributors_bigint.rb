class LocaleContributorsBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :locale_contributors, :id, :bigint, auto_increment: true
  end
end
