class CreateAkismetSubmissions < ActiveRecord::Migration[6.0]
  def change
    create_table :akismet_submissions do |t|
      t.belongs_to :item, polymorphic: true, null: false
      t.mediumtext :akismet_params, null: false
      t.boolean :result_spam, null: false
      t.boolean :result_blatant, null: false
    end
  end
end
