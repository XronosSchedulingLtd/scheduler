# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class InvigilationManager < TemplateManager

  KEY = "Invigilation"

  def self.template_type
    self.template_type_for(KEY)
  end

  def self.flush_cache
    self.flush_cache_for(KEY)
  end
end
