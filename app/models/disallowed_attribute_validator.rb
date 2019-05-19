class DisallowedAttributeValidator < ActiveModel::Validator
  def validate(record)
    DisallowedAttribute.where(object_type: options[:object_type]).each do |da|
      value = record.public_send(da.attribute_name)
      if value =~ Regexp.new(da.pattern)
        record.errors.add(:base, "Exception #{da.ob_code}")
        break
      end
    end
  end
end