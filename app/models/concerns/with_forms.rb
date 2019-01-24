# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

module WithForms
  extend ActiveSupport::Concern

  #
  #  Form is outstanding if we have form, but it's not complete.
  #
  def no_forms_outstanding?
    !self.user_form_response || self.user_form_response.complete?
  end

  def incomplete_ufr_count
    if self.user_form_response && !self.user_form_response.complete?
      1
    else
      0
    end
  end

  def corresponding_form
    self.user_form_response
  end

end
