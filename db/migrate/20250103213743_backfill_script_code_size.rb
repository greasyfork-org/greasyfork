class BackfillScriptCodeSize < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    Script.find_each do |script|
      script.update_column(:code_size, script.current_code.bytesize)
    end
  end
end
