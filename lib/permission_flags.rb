#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2022 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class PermissionFlags < Hash

  KNOWN_PERMISSIONS = [
    :editor,
    :can_repeat_events,
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
    :can_relocate_lessons,
    :can_view_forms,
    :admin,
    :can_view_unconfirmed,
    :can_edit_memberships,
    :can_api,
    :can_has_files,
    :can_view_journals,
    :can_make_shadows
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
    can_relocate_lessons: "Relocate lessons",
    can_view_forms:       "View forms",
    can_view_unconfirmed: "View unconfirmed",
    can_repeat_events:    "Repeating events",
    can_edit_memberships: "Edit members",
    can_api:              "Can use API",
    can_has_files:        "Can upload files",
    can_view_journals:    "Journals",
    can_make_shadows:     "Shadow events"
  }
  NICER_TEXT.default = "Pass"

  PERMISSION_NO        = 0
  PERMISSION_YES       = 1
  PERMISSION_DONT_CARE = 2

  @DEFAULT_VALUE = PERMISSION_NO

  #
  #  We store values 0, 1 or 2, but for convenenience interfacing
  #  with the front end, we will also accept "0", "1" or "2" and
  #  do the appropriate conversion.  For convenience of command
  #  line usage, accept true and false as well.
  #
  def []=(key, value)
    if KNOWN_PERMISSIONS.include?(key)
      unless value.is_a?(Numeric)
        if value.class == TrueClass
          value = PERMISSION_YES
        elsif value.class == FalseClass
          value = PERMISSION_NO
        else
          value = value.to_i
        end
      end
      if value > PERMISSION_DONT_CARE || value < PERMISSION_NO
        Rails.logger.debug("Attempt to assign out of range value (#{value}) to permission bit.")
      else
        super(key, value)
      end
    else
      Rails.logger.debug("Attempt to assign unknown permission key - #{key}")
    end
  end

  def self.default_value
    @DEFAULT_VALUE
  end

  #
  #  We will get attempts to access values before they are first
  #  defined.  Default to "0" (No) for bits which we understand,
  #  and to nil otherwise.
  #
  def [](key)
    if KNOWN_PERMISSIONS.include?(key)
      super || self.class.default_value
    else
      nil
    end
  end

  def self.permitted_keys
    KNOWN_PERMISSIONS
  end

  def self.nicer_text(key)
    NICER_TEXT[key]
  end
end

class ShadowPermissionFlags < PermissionFlags
  @DEFAULT_VALUE = PERMISSION_DONT_CARE
end

