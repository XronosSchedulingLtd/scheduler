# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class TemplateManager

  #
  #  Deliberately a class variable so it will be shared between all
  #  our descendants.
  #
  @@template_types = {}

  #
  #  This is a class level method so it can be used without instantiating
  #  an object and the result cached.
  #
  def self.template_type_for(purpose)
    #
    #  Note that there may be an entry in our cache which is nil.
    #  If there is then we've already looked for it but it wasn't there.
    #
    unless @@template_types.key?(purpose)
      @@template_types[purpose] = 
        RotaTemplateType.find_by(name: purpose)
    end
    @@template_types[purpose]
  end

  def self.flush_cache_for(purpose)
    @@template_types.delete(purpose)
  end

  def self.flush_all
    @@template_types = {}
  end
end
