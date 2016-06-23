# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


#
#  Note that this isn't a real Rails model - it doesn't inherit from
#  ActiveRecord at all.
#
class Teachinggroup

  def self.new
    g = Group.new
    g.persona_class = Teachinggrouppersona
    g
  end

  def self.current
    Group.current.where("persona_type = ?", "Teachinggrouppersona")
  end

  def self.where(given_hash)
    given_hash[:persona_type] = "Teachinggrouppersona"
    Group.where(given_hash)
  end

  #
  #  Typically called with: { :source_id => 1234 }
  #
  def self.find_by(given_hash)
    self.where(given_hash).take
  end

end
