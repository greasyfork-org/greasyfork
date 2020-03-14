module NodeExtensions
  def unlink
    puts to_html unless %w[rel class id style width height border target aria-hidden].include?(name) || ((name == 'src') && value.starts_with?('http:'))
    super
  end
end

module Nokogiri
  module XML
    class Node
      prepend NodeExtensions
    end
  end
end

deleted_nodes = []

Script.find_each do |s|
  deleted_nodes = []
  sv = s.newest_saved_script_version
  puts s.id.to_s
  sv.format_user_text(sv.additional_info, sv.additional_info_markup)
end
