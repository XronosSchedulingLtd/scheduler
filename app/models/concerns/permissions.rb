module Permissions
  extend ActiveSupport::Concern

  def permissions=(values)
    values.each do |key, value|
      key = key.to_sym
      if PermissionFlags.permitted_keys.include?(key)
        #
        #  Now the only values which we permit are all strings.
        #
        #  "0" - False
        #  "1" - True
        #  "2" - Don't care.
        #
        #  Everything always arrives from the browser as a string.
        #  The PermissionFlags model will convert them to integers
        #  for storage.
        #
        if value == "0" || value == "1" || value == "2"
          self.permissions[key] = value
        else
          self.permissions[key] = "2"
        end
      else
        Rails.logger.debug("Don't know key #{key}")
      end
    end
  end

end
