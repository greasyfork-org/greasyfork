module FormName
  def name_for(object_name, _options = {})
    hidden_field(object_name).match(/name="(.+?)"/)[1]
  end
end

ActionView::Helpers::FormBuilder.include FormName
