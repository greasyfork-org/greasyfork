class LibraryUsageStatistics
  def self.refresh_usages
    script_to_library_usages = {}
    Script.select(:id, :language).where(language: :js).find_each do |script|
      library_usages = Set.new
      script_to_library_usages[script.id] = library_usages
      script.meta['require']&.each do |require_url|
        script_id = UrlToScriptService.to_script(require_url, verify_existence: false)
        next unless script_id.is_a?(Integer)

        library_usages << script_id
      end
    end

    # Verify existence. UrlToScriptService can do this but we want to batch it.
    all_library_script_ids = script_to_library_usages.values.map(&:to_a).flatten.to_set
    existing_library_script_ids = Set.new(Script.where(id: all_library_script_ids).pluck(:id))
    deleted_library_ids = all_library_script_ids - existing_library_script_ids
    script_to_library_usages.values.each do |library_ids|
      library_ids.delete_if { |lib_id| deleted_library_ids.include?(lib_id) }
    end

    current_library_usages = LibraryUsage.pluck(:script_id, :library_script_id).group_by(&:first).transform_values { |v| v.to_set(&:last) }
    script_to_library_usages.each do |script_id, library_usages|
      saved_library_ids = current_library_usages.fetch(script_id, Set.new)
      to_delete = saved_library_ids - library_usages
      to_add = library_usages - saved_library_ids
      LibraryUsage.where(script_id: script_id, library_script_id: to_delete).delete_all if to_delete.any?
      LibraryUsage.insert_all(to_add.map { |library_script_id| { script_id: script_id, library_script_id: library_script_id } }) if to_add.any?
    end
  end
end
