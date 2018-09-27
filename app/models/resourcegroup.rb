# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


#
#  Note that this isn't a real Rails model - it doesn't inherit from
#  ActiveRecord at all.
#
class Resourcegroup

  def self.create!(params)
    myparams = {persona_class: Resourcegrouppersona}
    Group.create!(myparams.merge(params))
  end

  def self.new(params = nil)
    myparams = {persona_class: Resourcegrouppersona}
    if params
      myparams.merge!(params)
    end
    g = Group.new(myparams)
    g
  end

  def self.current
    Group.current.where("persona_type = ?", "Resourcegrouppersona")
  end

  def self.where(given_hash)
    given_hash[:persona_type] = "Resourcegrouppersona"
    Group.where(given_hash)
  end

  #
  #  Typically called with: { :source_id => 1234 }
  #
  def self.find_by(given_hash)
    self.where(given_hash).take
  end

  def self.find(id)
    Group.find(id)
  end

  def self.all
    Group.where(persona_type: "Resourcegrouppersona")
  end

  def self.count
    Group.where(persona_type: "Resourcegrouppersona").count
  end

end
