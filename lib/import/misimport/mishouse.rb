# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


#
#  These don't actually get loaded into the database, so they don't
#  descend from MIS_Record.  They are used solely for creating some
#  automatic groups.
#
class MIS_House
  #
  #  MIS-specific code is responsible for providing these.
  #
  attr_reader :name, :housemaster, :tugs

  #
  #  And should override the definition of this.
  #

  def self.construct(loader, mis_data)
    []
  end

end
