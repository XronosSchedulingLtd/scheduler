# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module Generator
  extend ActiveSupport::Concern

  included do
    has_many :proto_events, :as => :generator

  end

  module ClassMethods
  end

end
