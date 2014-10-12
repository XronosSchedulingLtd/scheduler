# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  Note that this isn't a real Rails model - it doesn't inherit from
#  ActiveRecord at all.
#
class Vanillagroup

  def self.new(params_hash = nil)
    g = Group.new
    g.persona_class = Vanillagrouppersona
    if params_hash
      params_hash.each do |key, value|
        g.send("#{key}=", value)
      end
    end
    g
  end

  def self.current
    Group.current.where("persona_type IS NULL")
  end

  def self.where(given_hash)
    given_hash[:persona_type] = nil
    Group.where(given_hash)
  end

  #
  #  Typically called with: { :staff_id => 1234, :era_id => 2 }
  #
  def self.find_by(given_hash)
    self.where(given_hash).take
  end

  def self.find(id)
    Group.find(id)
  end
end
