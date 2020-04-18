#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

#
#  A vanillagrouppersona is an empty class, but it needs to exist.
#  Test that it does.
#

class VanillagrouppersonaTest < ActiveSupport::TestCase

  test "Vanillagrouppersona exists" do
    #
    #  This is strangely convoluted.  Ruby offers a "defined?" method,
    #  but Rails auto-loads model sources when they are first referenced.
    #
    #  This means that if you just call defined? you are liable to get
    #  false, even though it could be defined if you actually accessed it.
    #
    begin
      Vanillagrouppersona
      assert defined? Vanillagrouppersona
    rescue NameError => error
      assert false, "Vanillagrouppersona should exist"
    end
  end

end
