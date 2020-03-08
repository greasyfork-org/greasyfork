class BackfillCodeHash < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    ScriptCode.where(code_hash: nil).find_each { |sc| sc.code_hash = Digest::SHA1.hexdigest sc.code; sc.save }
  end
end
