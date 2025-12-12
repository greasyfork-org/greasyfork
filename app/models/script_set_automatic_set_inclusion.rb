class ScriptSetAutomaticSetInclusion < ApplicationRecord
  belongs_to :parent, class_name: 'ScriptSet', touch: true
  belongs_to :script_set_automatic_type

  def i18n_params
    return ['script_sets.auto_set_types.all_scripts', {}] if script_set_automatic_type_id == 1
    return ['script_sets.auto_set_types.site', { site: value }] if (script_set_automatic_type_id == 2) && !value.nil? && !value.empty?
    return ['script_sets.auto_set_types.all_sites', {}] if script_set_automatic_type_id == 2
    return ['script_sets.auto_set_types.user', { user: User.find(value).name }] if script_set_automatic_type_id == 3
    return ['script_sets.auto_set_types.locale', { locale_name: Locale.find(value).display_text(in_locale: I18n.locale) }] if script_set_automatic_type_id == 4
  end

  def param_value
    return "#{script_set_automatic_type_id}-#{value}"
  end

  def self.from_param_value(value, exclusion: false)
    parts = value.split('-', 2)
    return ScriptSetAutomaticSetInclusion.new({ script_set_automatic_type_id: parts[0], value: parts[1], exclusion: })
  end

  def scripts(script_subset)
    case script_set_automatic_type.id
    when 1
      Script.listable(script_subset)
    when 2
      if value.present?
        Script.listable(script_subset).joins(:site_applications).where(site_applications: { domain_text: value })
      else
        Script.listable(script_subset).for_all_sites
      end
    when 3
      Script.listable(script_subset).joins(:authors).where(authors: { user_id: value })
    when 4
      Script.listable(script_subset).includes(:localized_names).where('localized_script_attributes.locale_id' => value)
    end
  end
end
