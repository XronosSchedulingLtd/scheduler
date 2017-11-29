module PermissionBits
  extend ActiveSupport::Concern

  included do
    serialize :permissions, Permissions
  end

  class Permissions < Hash

    KNOWN_PERMISSIONS = [
      :admin,
      :editor,
      :can_add_resources,
      :can_add_notes,
      :edit_all_events,
      :subedit_all_events,
      :privileged,
      :can_has_groups,
      :public_groups,
      :can_has_forms,
      :can_find_free,
      :can_add_concerns,
      :can_roam,
      :can_su,
      :exams,
      :can_relocate_lessons
    ]

    NICER_TEXT = {
      admin:                "Admin",
      editor:               "Events",
      can_add_resources:    "Add resources",
      can_add_notes:        "Add notes",
      edit_all_events:      "Edit all",
      subedit_all_events:   "Subedit all",
      privileged:           "Privileged",
      can_has_groups:       "Groups",
      public_groups:        "Public",
      can_has_forms:        "Forms",
      can_find_free:        "Find free",
      can_add_concerns:     "Adjust view",
      can_roam:             "Can roam",
      can_su:               "Can su",
      exams:                "Exams",
      can_relocate_lessons: "Relocate lessons"
    }
    NICER_TEXT.default = "Pass"

#    def []=(key, value)
#      puts ("Key #{key} assigned value #{value}")
#      super
#    end

    #
    #  We will get attempts to access values before they are first
    #  defined.  Default to 0 (No).
    #
    def [](key)
      super || "0"
    end

    def self.permitted_keys
      KNOWN_PERMISSIONS
    end

    def self.nicer_text(key)
      NICER_TEXT[key]
    end
  end

  def permissions=(values)
    Rails.logger.debug("Entering permissions=")
    Rails.logger.debug("Existing key values")
    self.permissions.each do |key, value|
      Rails.logger.debug("Key \"#{key}\" - value \"#{value}\".")
    end
    values.each do |key, value|
      key = key.to_sym
      if Permissions.permitted_keys.include?(key)
        #
        #  Now the only values which we permit are all strings.
        #
        #  "0" - False
        #  "1" - True
        #  "2" - Don't care.
        #
        #  Everything always arrives from the browser as a string
        #
        if value == "0" || value == "1" || value == "2"
          self.permissions[key] = value
        else
          Rails.logger.debug("TSCB returned value \"#{value}\".")
          self.permissions[key] = "2"
        end
      else
        Rails.logger.debug("Don't know key #{key}")
      end
    end
    Rails.logger.debug("Leaving permissions=")
  end

end
