# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi
  class Engine < ::Rails::Engine
    isolate_namespace PublicApi
  end
end
