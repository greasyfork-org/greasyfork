class NepaliLocalName < ActiveRecord::Migration[8.1]
  def change
    Locale.find_by(code: 'ne')&.update!(native_name: 'नेपाली')
  end
end
