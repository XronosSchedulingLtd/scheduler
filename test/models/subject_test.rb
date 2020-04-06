#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class SubjectTest < ActiveSupport::TestCase
  setup do
    @entity_class = Subject
    @valid_params = {
      name: "A subject"
    }
  end

  include CommonEntityTests

end
