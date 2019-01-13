# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module Persona
  extend ActiveSupport::Concern

  included do
    has_one :group, :as => :persona

  end

  module ClassMethods
  end

  #
  #  Default to true, but individual personae may override this.
  #
  def user_editable?
    true
  end

  #
  #  And this defaults to false, but will be true for ResourceGroups.
  #
  def can_have_requests?
    false
  end
end
