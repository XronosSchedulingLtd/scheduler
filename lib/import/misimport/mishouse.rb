
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
end
