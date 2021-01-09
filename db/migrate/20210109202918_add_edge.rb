class AddEdge < ActiveRecord::Migration[6.1]
  def up
    Browser.create!(name: 'Edge', code: 'edge')
  end
end
