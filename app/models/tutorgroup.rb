# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.


#
#  Note that this isn't a real Rails model - it doesn't inherit from
#  ActiveRecord at all.
#
class Tutorgroup

  def self.new
    g = Group.new
    g.persona_class = Tutorgrouppersona
    g
  end

  def self.current
    Group.current.where("persona_type = ?", "Tutorgrouppersona")
  end

  def self.where(given_hash)
    #
    #  Does anything need re-directing to a join?
    #
    if given_hash[:staff_id] ||
       given_hash[:house] ||
       given_hash[:start_year]
      #
      #  Need to split this up.
      #
      outer_hash = Hash.new
      inner_hash = Hash.new
      given_hash.each do |key, value|
        if key == :staff_id ||
           key == :house ||
           key == :start_year
          inner_hash[key] = value
        else
          outer_hash[key] = value
        end
      end
      outer_hash[:tutorgrouppersonae] = inner_hash
      Group.joins(:tutorgrouppersona).where(outer_hash)
    else
      given_hash[:persona_type] = "Tutorgrouppersona"
      Group.where(given_hash)
    end
  end

  #
  #  Typically called with: { :staff_id => 1234, :era_id => 2 }
  #
  def self.find_by(given_hash)
    self.where(given_hash).take
  end
end
